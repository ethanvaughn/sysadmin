package dao::cclog;
#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = qw(&getUsernameList);

use strict;


#----- getCCLog -------------------------------------------------------
# parameters: (dbh)
# returns dataset of CCLog records.
sub getCCLog {
    my $dbh = shift;

    my $sql = <<SQL;
        SELECT time, user_name, state, card_id 
        FROM cclog
        ORDER BY time
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	my @data;
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	return \@data;
}



1;
