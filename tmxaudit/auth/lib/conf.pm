package lib::conf;
# Application-wide properties, constants, configs..

use FindBin qw( $Bin );
use lib "$Bin/..";

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($CLIENTDIR);

use strict;

#our $CLIENTDIR = "/u01/home/tmxaudit/clientauth";
our $CLIENTDIR = "/tmp/clientauth";

1
