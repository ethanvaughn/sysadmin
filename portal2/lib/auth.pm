package lib::auth;

use FindBin qw( $Bin );
use lib "$Bin/..";

#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = qw($PROXY_IP $DATAPATH $JSON_HEADER $JSON_FOOTER);

use strict;

use JSON;

use lib::conf;



#----- authenticate ----------------------------------------------------------
# Returns boolean
sub authenticate {
	my $username = shift;
	my $password = shift;

	if (!$username || !$password) {
		return 0;
	}
	
	# TODO: authenticate from a datasource: ldap?
	# For now credentials are hard-coded here:
	my $credentials = {
		evaughn => 'test',
		tnorris => 'test',
	    ratuser => 'test',
		dwuser  => 'test',
		racuser => 'test',
		pcuser  => 'test',
		pamuser => 'test'
	};

	my $result = 0;
	if ($credentials->{$username} eq $password) {
		$result = 1;
	}

	return $result;
}




#----- isAdminUser ----------------------------------------------------------
# Returns boolean if user is non-cust group (ie. privileged).
sub isAdminUser {
	my $group = shift;

	my $result = 0;

	if ($group eq 'sa'  || 
	    $group eq 'dba' || 
	    $group eq 'tomax' ) {
		$result = 1;
	}
	
	return $result;
}




#----- initSession ----------------------------------------------------------
# On successful authentication initialize session from the profile 
# datasources (ldap, DB, files, etc.)
sub initSession {
print STDERR "initSession\n";
	my $SESSION   = shift;
	my $username  = shift;
	
	my $profile = getProfile( $username );

	$SESSION->param( 'username',  $username );
	$SESSION->param( 'group',     $profile->{group} )      if ($profile);
	$SESSION->param( 'cust_code', $profile->{cust_code} )  if ($profile);

	return $SESSION;
}




#----- validateSession ----------------------------------------------------------
# Returns boolean.
sub validateSession {
print STDERR "validateSession\n";
	my $CGI     = shift;
	my $SESSION = shift;

	if (!$SESSION) {
		print STDERR "Session undef.\n";
		$SESSION->delete();
		$SESSION->flush();
		return (0);
	}

	if ( $SESSION->is_expired ) {
		print STDERR "Session has expired.\n";
		$SESSION->delete();
		$SESSION->flush();
		return (0);
	}

	if ( $SESSION->is_empty ) {
		print STDERR "Session exists but is empty.\n";
		$SESSION->delete();
		$SESSION->flush();
	}

	# Valid session. Now sanity check.
	# Ensure essential parameters exist in the session.
	my @missing;
	if (!$SESSION->param( 'username' )) {
		push( @missing, 'username' );
	}
	if (!$SESSION->param( 'group' )) { 
		push( @missing, 'group' );
	}
	if (@missing > 0) {
		print STDERR "Missing required session parameters:\n";
		foreach (@missing) {
			print STDERR "    $_\n";
		}
		print STDERR "Invalidating session.\n";
		$SESSION->delete();
		$SESSION->flush();
		return (0);
	}

	return 1;
}




#----- getGroup ----------------------------------------------------------
# Returns scalar group for the user, or empty if not found (no access).
# This is to simulate getting group from LDAP (ActiveDir?)
sub getGroup {
print STDERR "getGroup\n";
	my $username = shift;

	# TODO: Pull groups from a datasource: ldap?
	# For now groups are hard-coded here:
	my $grouplist = {
		evaughn => 'sa',
		tnorris => 'dba',
	    ratuser => 'rat',
		dwuser  => 'dw',
		racuser => 'rac',
		pcuser  => 'pc',
		pamuser => 'pam'
	};

	return $grouplist->{$username} if (exists( $grouplist->{$username} ));
}




#----- getCustList --------------------------------------------------------
# Create HoH customer list.
sub getCustList {
	my $custlist;
	my $custlist_json = '{';
	my $datafile = $DATAPATH . '/custlist.json';
	if (open( DATAFILE, "<$datafile" )) {
		while (<DATAFILE>) {
			chomp;
			$custlist_json .= $_;
		}
		close( DATAFILE );
		$custlist_json .= '}';
		$custlist = from_json( $custlist_json );
	} else {
		appendError( "main::action_get[custs]  Unable to open file [$datafile] for reading: $!\n" );
	}
	
	return $custlist->{custs};
}




#----- lookupCustName --------------------------------------------------------
# Return the cust_name from the cust_code.
sub lookupCustName {
print STDERR "lookupCustName\n";
	my $cust_code = shift;
	
	my $custlist = getCustList();
print STDERR $custlist->{$cust_code} . "<--cust_name\n";	

	return $custlist->{$cust_code};
}




#----- getProfile --------------------------------------------------------
# Returns hashref or undef.
sub getProfile {
print STDERR "getProfile\n";	
	my $username = shift;

	my $datafile = $DATAPATH . '/profiles/' . $username . '-profile.json';
	my $profile;

	if (open( DATAFILE, "<$datafile" )) {
		my $profile_json;
		while (<DATAFILE>) {
			chomp;
			$profile_json .= $_; 
		}
		close( DATAFILE );
		$profile = from_json( $profile_json );
	} else {
		print STDERR "auth::getProfile  Unable to open file [$datafile] for reading: $!\n";
	}

	# Append group to profile from authentication datasource.
	$profile->{group} = getGroup( $username );
	
	return $profile;
}




#----- setProfile --------------------------------------------------------
# Returns boolean.
sub setProfile {
	my $username = shift;
	my $writable = shift;

	if (!$writable) {
		# Nothing to do ...
		return 1;
	}
	
	my $datafile = $DATAPATH . '/profiles/' . $username . '-profile.json';

	if (!open( DATAFILE, ">$datafile" )) {
		print STDERR "auth::updateProfile  Unable to open file [$datafile] for writing: $!\n";
		return 0;
	}
	
	print DATAFILE to_json( $writable );
	
	close( DATAFILE );
	
	return 1;
}





1;
