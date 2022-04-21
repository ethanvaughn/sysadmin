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



1;
