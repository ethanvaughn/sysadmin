package ac;
# Application-wide properties, constants, configs..

use FindBin qw( $Bin );
use lib "$Bin";

use conf;
use strict;

#----- normHostname ----------------------------------------------------------
# Downcap and strip the hostname from a fqdn.
# Returns normalized hostname.
sub normHostname {
	my $hostname = shift;

	chomp $hostname;

	# Set hostname to lowercase:
	$hostname =~ tr/[A-Z]/[a-z]/;

	# Strip the domain from the hostname:
	($hostname = $hostname) =~ s/^(.*?)[.].*$/$1/;

	return $hostname;
}



#----- getBundle -------------------------------------------------------------
# Connect to server via ssh and retreive the tar file containing auth files.
# Return empty string or an error message.
sub getBundle {
	my $server = shift;
	my $clienthostname = shift;

#	print "DEBUG: (getBundle) scp $USER\@$server:$CLIENTDIR/$clienthostname.tar $WORKDIR\n";

	print "Please type 'yes'\n";
	my @result = `scp $USER\@$server:$CLIENTDIR/$clienthostname.tar $WORKDIR 2>&1`;
	my $rcode = $?;

	if ($rcode == 0) {
		# Delete the remote file:
		@result = `ssh $USER\@$server rm -f $CLIENTDIR/$clienthostname.tar 2>&1`;
	}
		
	return $result[0];
}



#----- extractBundle -------------------------------------------------------------
# Parameters ( path_to_tar_file, tar_file_name )
# Extract and test the tar bundle.
# Return empty string or an error message.
sub extractBundle {
	my $path = shift;
	my $file = shift;

	if (-z "$path/$file") {
		return "File size is zero!";
	}
	
	my @result = `cd $path; tar xf $file 2>&1`;
	my $rcode = $?;

	# Ignore warnings (data/time skew, etc)
	if ($rcode == 0) {
		$result[0] = "";
	}

	return $result[0];
}



#----- getLocalPasswd -------------------------------------------------------------
# Parameters ( passwd_path, passwd_local, shadow_path, shadow_local )
# Extract and write just the local portions of a given passwd file. The local 
# portion are those records with uid < 40000.
# Note: this function also creates the corresponding shadow file.
# Return empty string or an error message.
sub getLocalPasswd {
	my $passwd = shift;
	my $passwd_out = shift;
	my $shadow = shift;
	my $shadow_out = shift;

	my %userhash = ();

	open( PASSWD, "<$passwd" ) || return $!;
	open( PASSWD_OUT, ">$passwd_out" ) || return $!;

	while (<PASSWD>) {
		my @rec = split(/:/);
		chomp $rec[2]; #uid
		my $uid = $rec[2];
		my $username = $rec[0];

		if ($uid < 40000 || $uid > 69999) {
			# Check to see if this username also exists in the remote file.
			`grep '^$username:' $WORKDIR/passwd.r`;
			my $result = $?;
			if ($result == 0) {
				return "The username [$username] is duplicate in local and remote passwd files!";
			}
			print PASSWD_OUT $_;
			# Capture a map of usernames corresponding to the local portion:
			$userhash{$rec[0]} =  $rec[0];
		}
	}
	close( PASSWD );
	close( PASSWD_OUT );
	if (-z $passwd_out) {
		return "The file [$passwd_out] has zero bytes!";
	}	


	open( SHADOW, "<$shadow" ) || return $!;
	open( SHADOW_OUT, ">$shadow_out" ) || return $!;
	while (<SHADOW>) {
		my @rec = split(/:/);
		chomp $rec[0]; #username
		my $username = $rec[0];
		if ($userhash{$username}) {
			print SHADOW_OUT $_;
		}
	}
	close( SHADOW );
	close( SHADOW_OUT );
	if (-z $shadow_out) {
		return "The file [$shadow_out] has zero bytes!";
	}	

	return "";
}



#----- getLocalGroup -------------------------------------------------------------
# Parameters ( path_to_group_file_source, path_to_local_target )
#
# Extract and write just the local portions of a given group file. The local 
# portion are those records with gid < 40000. #
#
# Note: a duplication of a group between the remote and local files will return an
# error message.
#
# Return empty string or an error message.
sub getLocalGroup {
	my $group = shift;
	my $out = shift;

	open( GROUP, "<$group" ) || return $!;
	open( OUT, ">$out" ) || return $!;

	while (<GROUP>) {
		my @rec = split(/:/);
		my $groupname = $rec[0];
		chomp( $rec[2] );

		my $gid = $rec[2];
		if ($gid < 40000 || $gid > 69999) {
			# Check to see if this group also exists in the remote file.
			`grep '^$groupname:' $WORKDIR/group.r`;
			my $result = $?;
			if ($result == 0) {
				return "The group [$groupname] is duplicate in local and remote group files!";
			}
			# Not duplicate, write to file:
			print OUT $_;
		}
	}
	close( GROUP );	
	close( OUT );	
	if (-z $out) {
		return "The file [$out] has zero bytes!";
	}	

	return "";
}


#----- mkComposit ------------------------------------------------------------
# Parameters ( workpath, outpath )
# Combine the local and remote pieces.
sub mkComposit {
	my $workpath = shift;
	my $outpath = shift;

	my @res = ();	

	@res = `cat $workpath/passwd.l $workpath/passwd.r > $outpath/passwd 2>&1`;
	@res = `cat $workpath/shadow.l $workpath/shadow.r > $outpath/shadow 2>&1`;
	@res = `cat $workpath/group.l  $workpath/group.r  > $outpath/group 2>&1`;
	
	return $res[0];
}



#----- chkEmpty --------------------------------------------------------------
# Paramenters ( file1, file2, ..., fileN )
# Checks given files for zero byte.
# Returns composit message of all files that are empty.
# Returns empty string on success.
sub chkEmpty {
	my @filelist = @_;

	my $msg = "";
	my $empty_files = "";

	foreach my $file (@filelist ) {
		if (-z $file) {
			$empty_files .= "    $file\n";
		}
	}
	if ($empty_files ne "") {
		$msg = "The following files are empty:\n" . $empty_files;
	}

	return $msg;
}



#----- verifyAccounts --------------------------------------------------------
# Verify the existence of certain key accounts:
# Parameters ( fileslist, accountlist, grouplist )
# filelist is an array with the path the passwd[0], shadow[1], and group[2] files.
# Returns empty string upon success, or list of missing accounts  on fail.
sub verifyAccounts {
	my $filelist = shift;
	my $accountlist = shift;
	my $grouplist = shift;

	my $msg = "";

	my $missing = "";
	open( PASSWD, "<@$filelist[0]") or die;
	my @passwd = <PASSWD>;
	close( PASSWD );
	OUTTER: foreach my $account (@$accountlist) {
#		print "DEBUG: account = [$account]\n";
		foreach my $line (@passwd) {
			chomp $line;
#			print "DEBUG: line = [$line]\n";
			if ($line =~ /$account/) {
#				print "    DEBUG: $line =~ /$account/\n";
				next OUTTER;
			}
		}
		$missing .= "$account\n";
	}
	if ($missing ne "") {
		$msg .= "The following key accounts are missing from passwd:\n" . $missing;
	}

	my $missing = "";
	open( SHADOW, "<@$filelist[1]") or die;
	my @shadow = <SHADOW>;
	close( SHADOW );
	OUTTER: foreach my $account (@$accountlist) {
		foreach my $line (@shadow) {
			chomp $line;
			if ($line =~ /$account/) {
				next OUTTER;
			}
		}
		$missing .= "$account\n";
	}
	if ($missing ne "") {
		$msg .= "The following key accounts are missing from shadow:\n" . $missing;
	}

	my $missing = "";
	open( GROUP, "<@$filelist[2]") or die;
	my @group = <GROUP>;
	close( GROUP );
	OUTTER: foreach my $account (@$grouplist) {
		foreach my $line (@group) {
			chomp $line;
			if ($line =~ /$account/) {
				next OUTTER;
			}
		}
		$missing .= "$account\n";
	}
	if ($missing ne "") {
		$msg .= "The following key groups are missing from group:\n" . $missing;
	}

	return $msg;
}



1
