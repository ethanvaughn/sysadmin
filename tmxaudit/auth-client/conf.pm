package conf;
# Application-wide properties, constants, configs..

use FindBin qw( $Bin );
use lib "$Bin";

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($USER $PASS $SERVER $CLIENTDIR $WORKDIR $HOMEROOT);

use strict;

# Remote user and host.
our $USER	= "tmxaudit";
our $PASS	= "cog4Hyt7";
our $SERVER	= "10.24.74.13";

# Remote directory to download authentication files.
our $CLIENTDIR = "clientauth";

# Local directory to receive the authentication files for parsing.
our $WORKDIR = "/u01/app/auth-client/work";

# Local home directory
our $HOMEROOT = "/u01/home";


1
