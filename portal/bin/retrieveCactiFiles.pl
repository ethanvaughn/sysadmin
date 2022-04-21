#!/usr/bin/perl

use strict;
use lib::auth;
use CGI;



my $dir = "/u01/app/";
chdir $dir or die "Cannot change to directory $dir: $!\n";
`rm -rf /u01/app/graphs`;
`wget -m -nH http://10.24.74.9/graphs`;
`wget -m -nH http://10.9.15.10/graphs`;
my $dir2 = "/u01/app/portal/";
chdir $dir2 or die "Cannot change to directory $dir: $!\n";
`./bin/renameCactiFiles.pl`;
