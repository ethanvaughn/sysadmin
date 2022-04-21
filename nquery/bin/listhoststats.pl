#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::statusdat;

use strict;



#----- Main ------------------------------------------------------------------

# Get the list and print
my @list;

#if ($ARGV[0]) {
#	@list = lib::statusdat::getStatusByHost( $ARGV[0] );
#} else {
#	@list = lib::statusdat::getStatus( '/u01/app/nagios/var/status.dat' );
#}
#
#foreach my $rhash (@list) {
#	print "$rhash->{firstline}\n";
#	foreach my $key (keys( %$rhash )) {
#		if ($key ne "firstline" and $key ne "lastline") {
#			print "$key=$rhash->{$key}\n";
#		}
#	}
#	print "$rhash->{lastline}\n";
#	print "\n";
#}

@list = lib::statusdat::getStatusByHost( $ARGV[0] );
foreach my $rec (@list) {
	if ($rec->{firstline} =~ /service/) {
		print $rec->{host_name} . ',';
		print $rec->{service_description} . ',';
		print $rec->{plugin_output} . ',';
		print $rec->{problem_has_been_acknowledged} . ',';
		print $rec->{scheduled_downtime_depth} . ',';
		print $rec->{current_state};
		print "\n";
	}
}

exit (0);
