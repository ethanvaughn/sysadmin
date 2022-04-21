package lib::cclog;
#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = qw(&getusernamelist);

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::cclog;

use strict;



#----- getCCLog ------------------------------------------------------------
# Parameters: ( $dbh )
# Returns array of hashref dataset of CCLog records.
sub getCCLog {
    my $dbh = shift;
    return dao::cclog::getCCLog( $dbh );
}


1;
