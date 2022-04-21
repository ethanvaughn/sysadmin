package lib::getgroup;

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::group;

use strict;


#----- getGidByName ---------------------------------------------------------- 
# Parameters: (dbh, name)
# 
sub getGidByName {
	my $dbh = shift;
	my $name = shift;
		
	return dao::group::getGidByName( $dbh, $name );
}


#----- getNextGid ---------------------------------------------------------- 
# Parameters: (dbh)
# 
sub getNextGid {
	my $dbh = shift;
		
	return dao::group::getNextGid( $dbh );
}



#----- getGroupData ---------------------------------------------------------- 
# Return a hash of all the group information showing which users are in
# each group. The key is the groupname. 
# Parameters: (dbh)
# 
sub getGroupData {
	my $dbh = shift;


	my %groupdata=();

	my $groupsref = dao::group::getAllGroups( $dbh );
	my $linksref = dao::group::getUserGroupLinks( $dbh );

	# Create a hash entry for each group using the group name as the key
	# and the gid as the first element in the contained array.
	foreach my $key (keys( %{$groupsref} )) {
		my @aryref = ( $groupsref->{$key}->{'gid'} );
		$groupdata{$key} = \@aryref;
	}
	# Now add the users into the array contained in the group hash record.
	foreach my $rowref (@{$linksref}) {
        push( @{$groupdata{$rowref->[1]}}, $rowref->[0] );
	}

	return %groupdata;
}


#----- mkGroup ----------------------------------------------------------
# Returns array-ref of scalar strings, each representing a line of the /etc/group file.
sub mkGroup {
	my $dbh = shift;

	my @result;
	
	my %groupdata = getGroupData( $dbh );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: $errstr";

	for my $groupname (keys(%groupdata)){
		my $rec = $groupname . ":x:"; 
		# Index 0 is the gid.
		$rec .= $groupdata{$groupname}->[0] . ":";
		# Loop through the usernames.
		my $count = $#{$groupdata{$groupname}};
		for (my $i=1; $i<=$count; $i++) {
			$rec .= "$groupdata{$groupname}->[$i]";
			if ($i != $count) {
				$rec .= ",";
			}
		}
		push ( @result, $rec );
	}
	
	return \@result;
}



1;
