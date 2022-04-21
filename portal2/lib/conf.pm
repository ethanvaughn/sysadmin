package lib::conf;

use FindBin qw( $Bin );
use lib "$Bin/..";

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($PROXY_IP $CONFPATH $DATAPATH $JSON_HEADER $JSON_FOOTER);

use strict;


our $PROXY_IP = '10.24.74.13';
our $CONFPATH = '/u01/app/portal2/conf';	
our $DATAPATH = '/u01/app/portal2/var';	

1;
