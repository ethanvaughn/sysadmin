package lib::conf;
# Common properties, constants, configs..

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($DBUSER $DBPASS $DBNAME $DBSTR);

use strict;

# DB credentials for connect string.
our $DBUSER = "portal";
our $DBPASS = 'p0rt@l';
our $DBNAME = "portal";
our $DBSTR  = "dbi:Pg:dbname=$DBNAME";


1
