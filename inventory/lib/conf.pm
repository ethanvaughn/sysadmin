package lib::conf;
# Common properties, constants, configs..

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($DBUSER $DBPASS $DBNAME $DBSTR);

use strict;

# DB credentials for connect string.
our $DBUSER = "appuser";
our $DBPASS = "ert5oiu7";
our $DBNAME = "ops";
our $DBSTR  = "dbi:Pg:dbname=$DBNAME";

1
