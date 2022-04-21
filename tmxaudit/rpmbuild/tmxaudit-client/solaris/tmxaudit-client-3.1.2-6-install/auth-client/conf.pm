package conf;
# Application-wide properties, constants, configs..

use FindBin qw( $Bin );
use lib "$Bin";

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($USER $HOST $CLIENTDIR $WORKDIR);

use strict;

# Remote user and host.
our $USER = "tmxaudit";
our $HOST = "10.24.74.13";

# Remote directory to download authentication files.
our $CLIENTDIR = "/u01/home/tmxaudit/clientauth";

# Local directory to receive the authentication files for parsing.
our $WORKDIR = "/u01/app/auth-client/work";

1
