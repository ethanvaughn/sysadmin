package ac;
# Application-wide properties, constants, configs..

use FindBin qw( $Bin );
use lib "$Bin";

use Net::FTP;

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


#----- getIP -----------------------------------------------------------------
sub getIP {
	my @tmp = `/sbin/ifconfig eth0`;
	foreach my $line (@tmp) {
		if ( $line =~ /.*inet addr:(.*) Bcast.*$/ ) {
			return $1;
		}
	}
	
	return '0.0.0.0';
}



#----- getBundle -------------------------------------------------------------
# Connect to server via ssh and retreive the tar file containing auth files.
# Return empty string or an error message.
sub getBundle {
	my $immediate = shift; # BOOL: if true, skip the initial wait.
	my $clientinfo = shift; # arrayref: [0]hostname, [1]ipaddr

	my $SPREAD	= 10; # Minutes for random spread
	my $SIGTO	= 300; # Set to 5 min. This is to catch anomolous network hangs.
	my $WAIT	= 30; # Time to wait between retry
	my $RETRY	= 3;

	if (!$immediate) {
		# Add a random stagger so auth-host doesn't get flooded.
		# This spreads the ssh connections randomly over a 10 minute period.
		my $RAND = ( rand($SPREAD) * 60 );
		print "Waiting [$RAND] seconds before execution.\n";
		sleep( $RAND );
	}

	my $file	= $clientinfo->[0] . '.tar';
	my $ipaddr	= $clientinfo->[1];

	my $errmsg;

	$SIG{ALRM} = sub { 
		die "SIG:TIMEOUT retrieving file [$SERVER]:[$file] on host [$ipaddr].\n"; 
	};

	my $i=0;
	for ($i=1; $i<=$RETRY; $i++) {
		$errmsg = '';
		eval {
			alarm( $SIGTO );

			my $ftp = Net::FTP->new( $SERVER, Debug => 0, Passive => 1, Timeout => 30 )
			  or die "Cannot connect to $SERVER from host [$ipaddr]: $@";

			$ftp->login( $USER, $PASS )
			  or die 'Cannot log in: ', $ftp->message;

			$ftp->binary()
			  or die 'Cannot set binary transfers: ', $ftp->message;

			$ftp->cwd( $CLIENTDIR )
			  or die "Cannot cd to dir [$CLIENTDIR] from host [$ipaddr]: ", $ftp->message;

			$ftp->get( $file, "$WORKDIR/$file" )
			  or die "Unable to get file [$file] from host [$ipaddr]: ", $ftp->message;

			$ftp->delete( $file )
			  or die "Unable to delete file [$file] from host [$ipaddr]: ", $ftp->message;

			$ftp->quit;

			alarm( 0 );
		}; #eval

		if ($@) {
			$errmsg = $@;
			# Enter the retry for other errors.
			sleep( $WAIT ) unless $i == $RETRY;
		} else {
			# Exit the retry loop:
			last;
		}

	}

	return $errmsg;
} #getBundle




#----- extractBundle -------------------------------------------------------------
# Parameters ( path_to_tar_file, tar_file_name )
# Extract and test the tar bundle.
# Return empty string or an error message.
sub extractBundle {
	my $path = shift;
	my $file = shift;

	if (-z "$path/$file") {
		return 'File size is zero!';
	}
	
	my @result = `cd $path; tar xf $file 2>&1`;
	my $rcode = $?;

	# Ignore warnings (data/time skew, etc)
	if ($rcode == 0) {
		$result[0] = '';
	}

	return $result[0];
}



#----- getLocalPasswd -------------------------------------------------------------
# Parameters ( passwd_path, passwd_local, shadow_path, shadow_local )
# Extract and write just the local portions of a given passwd file. The local 
# portion are those records with uid < 40000 or > 69999 and not (the root 
# account is maintained centrally.)
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

		if (($uid < 40000 || $uid > 69999) && $uid != 0) {
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

	return '';
}



#----- getLocalGroup -------------------------------------------------------------
# Parameters ( path_to_group_file_source, path_to_local_target )
#
# Extract and write just the local portions of a given group file. The local 
# portion are those records with gid < 40000 or > 69999 and not 0 (root is 
# managed centrally). 
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
		if (($gid < 40000 || $gid > 69999) && $gid != 0) {
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

	return '';
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

	my $msg = '';
	my $empty_files = '';

	foreach my $file (@filelist ) {
		if (-z $file) {
			$empty_files .= "    $file\n";
		}
	}
	if ($empty_files ne '') {
		$msg = "The following files are empty:\n" . $empty_files;
	}

	return $msg;
}



#----- verifyAccounts --------------------------------------------------------
# Verify the existence of certain key accounts:
# Parameters ( fileslist, accountlist, grouplist )
# filelist is an array with the path to the passwd[0], shadow[1], and group[2] files.
# Returns empty string upon success, or list of missing accounts  on fail.
sub verifyAccounts {
	my $filelist = shift;
	my $accountlist = shift;
	my $grouplist = shift;

	my $msg = '';

	my $missing = '';
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
	if ($missing ne '') {
		$msg .= "The following key accounts are missing from passwd:\n" . $missing;
	}

	my $missing = '';
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
	if ($missing ne '') {
		$msg .= "The following key accounts are missing from shadow:\n" . $missing;
	}

	my $missing = '';
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
	if ($missing ne '') {
		$msg .= "The following key groups are missing from group:\n" . $missing;
	}

	return $msg;
}



#----- setHomeDirs --------------------------------------------------------
# Create and delete home dirs for each remote user.
# Parameters:
#     rfiles   = arrayref of the paths to the remote files in the 
#                form ([0]passwd, [1]shadow, [2]group).
#     homeroot = path to the system home dir (eg. /u01/home)
sub setHomeDirs {
	my $rfiles   = shift;
	my $homeroot = shift;

	# Make a hash of the remote groups keyed by gid:
	my %grouphash;
	open( RGROUP, "<$rfiles->[2]") or die;
	my @groups = <RGROUP>;
	close( RGROUP );
	foreach my $group (@groups) {
		my @fields = split( /:/, $group );
		$grouphash{$fields[2]} = $fields[0];

		# Make sure the group directories exist.
		my $dir = "$homeroot/$fields[0]";
		if (! -d $dir) {
			print STDERR "mkdir $dir\n";
			mkdir( $dir );
			chown( 0, $fields[2], ("$dir") );
			`chmod 775 $dir`;
		}
		
		# Always set the permissions and ownership:
		chown( 0, $fields[2], ($dir) ) || 
			print STDERR "Unable to chown 0, $fields[2], ($dir)\n";
		chmod( 0755, ($dir) ) ||		
			print STDERR "Unable to chmod  0755, ($dir)\n";
	}
	
	
	# Loop through the users and ensure a corresponding directory exists, 
	# create if not.
	# Also, make a username hash to for later lookup.
	my %userhash;
	open( RPASSWD, "<$rfiles->[0]") or die;
	my @passwd = <RPASSWD>;
	close( RPASSWD );
	foreach my $rec (@passwd) {
		my @fields = split( /:/, $rec );
		my $username = $fields[0];
		my $uid      = $fields[2];
		my $gid      = $fields[3];
		
		my $dir = "$homeroot/$grouphash{$gid}/$username";
		if (! -d $dir) {
			print STDERR "mkdir $dir\n";
			mkdir( $dir );
			`cp /u01/app/auth-client/screenrc $dir/.screenrc`;
			`cp /etc/skel/.bash* $dir`;
			`chown -R $uid:$gid $dir`;
		}
		# Always reset the permissions and ownership:
		chown( $uid, $gid, ($dir) ) || 
			print STDERR "Unable to chown $uid, $gid, ($dir)\n";
		chmod( 0755, ($dir) ) ||		
			print STDERR "Unable to chmod  0755, ($dir)\n";

		$userhash{$username} = $username;		
	}
	
	
	# Loop through current dirs and check for a matching account, remove
	# directories and files that don't match an existing account name.
	# Therefore, we should be left with only the personal home dirs.
	foreach my $key (keys( %grouphash )) {
		my $gdir = "$homeroot/$grouphash{$key}";
		if (opendir( DIR, $gdir )) {
			my $userdir; # This includes any files crufting-up the group-home dir ...
			while (defined( $userdir = readdir( DIR ) )) {
				if (!exists( $userhash{$userdir} ) && $userdir ne "." && $userdir ne "..") {
					my $rmout = `rm -rf $gdir/$userdir`;
					print STDERR $rmout; 
				}
			}
			closedir( DIR );
		} else {
			# The groupdir is missing. Create it and set permissions.
			mkdir( $gdir );
			chown( 0, $key, ($gdir) ) || 
				print STDERR "Unable to chown 0, $key, ($gdir)\n";
			chmod( 0755, ($gdir) ) ||		
				print STDERR "Unable to chmod  0755, ($gdir)\n";
		}
	}
	
} #setHomeDirs



#----- setDefaultPolicies ----------------------------------------------------
# Set some misc policies. 
sub setDefaultPolicies {
	my $lfiles = shift;
	my $rfiles = shift;

	my $bin = '/u01/app/adminscripts';

	## Policies for local accounts
	# Loop through local users:
	open( LPASSWD, "<$lfiles->[0]") or die;
	my @passwd = <LPASSWD>;
	close( LPASSWD );
	foreach my $rec (@passwd) {
		my @fields = split( /:/, $rec );
		my $username = $fields[0];
		my $uid      = $fields[2];
		my $gid      = $fields[3];
		my $homedir  = $fields[5];

		# Create a .screenrc for non-system local accounts 
		if ($uid > 99) {
			`[ ! -f $homedir/.screenrc ] && cp /u01/app/auth-client/screenrc $homedir/.screenrc`;
		}
		
	}
		

	## Policies for remote accounts
	# Make a hash of the remote groups keyed by gid:
	my %grouphash;
	open( RGROUP, "<$rfiles->[2]") or die;
	my @groups = <RGROUP>;
	close( RGROUP );
	foreach my $group (@groups) {
		my @fields = split( /:/, $group );
		$grouphash{$fields[2]} = $fields[0];
	}

	# Loop through remote users:
	open( RPASSWD, "<$rfiles->[0]") or die;
	my @passwd = <RPASSWD>;
	close( RPASSWD );
	foreach my $rec (@passwd) {
		my @fields = split( /:/, $rec );
		my $username = $fields[0];
		my $uid      = $fields[2];
		my $gid      = $fields[3];
		
		# Lookup the user's primary group name:
		my $gname    = $grouphash{$gid};
		my $dir      = "/u01/home/$gname/$username";

		# Ensure all remote users have .bash* and .screenrc files without overwriting
		`[ ! -f $dir/.bash_logout ]  && cp /etc/skel/.bash_logout  $dir/.bash_logout`;
		`[ ! -f $dir/.bash_profile ] && cp /etc/skel/.bash_profile $dir/.bash_profile`;
		`[ ! -f $dir/.bashrc ]       && cp /etc/skel/.bashrc       $dir/.bashrc`;
		`[ ! -f $dir/.screenrc ]     && cp /u01/app/auth-client/screenrc $dir/.screenrc`;
		
		# Set up shareable pts for running screen in a system account:
		`(grep ".*SSH_TTY.*" $dir/.bash_profile &>/dev/null) || /bin/echo '[ \$SSH_TTY ] && chmod o+rw \$SSH_TTY' >> $dir/.bash_profile`;

		if ($gname eq 'sysdba') {
			# All users with sysdba as primary group get added to the dba group:
			`$bin/groupappend.pl -g dba -u $username`;
	
			# All users with sysdba as primary group get added to the vncusers group:
			`$bin/groupappend.pl -g vncusers -u $username`;
		}
		
		# Finally, set ownership and permissions on the home dir.
		# Note: The -R on this chown caused a bug: if the user has a symlink
		# in their home dir, the -R would recurse to the symlink and change
		# the target directory ownership as well. 
		`chown $username:$gname $dir`;
	}
	
	
}



1
