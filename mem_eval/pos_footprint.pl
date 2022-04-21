#!/usr/bin/perl
#
# Grab a snapshot of the RSS of the current pos processes and 
# compare to the total mem used on the system.

#use strict;

# Get current mem and swap used.
my @free_out = `free`;

$free_out[2] =~ s/^\s+//; # trim leading ws
my @tmp = split( /\s+/, $free_out[2] );
my $mem_used = $tmp[2];

$free_out[3] =~ s/^\s+//; #trim leading ws 
@tmp = split( /\s+/, $free_out[3] );
my $swp_used = $tmp[2];

# Gather up the RSS for the pos programs.
my $ps_cnt = 0;
my $tot_rss = 0;
my $avg_rss = 0;
my %stats;
my $cmdpath = "~/mem_eval";

# delme:
my @result;

$stats{ "crdtmon" } = &sumrss( "$cmdpath/ps_crdtmon.sh" );
$ps_cnt += $stats{ "crdtmon" }->[0];
$tot_rss += $stats{ "crdtmon" }->[1];

$stats{ "otranpost" } = &sumrss( "$cmdpath/ps_otranpost.sh" );
$ps_cnt += $stats{ "otranpost" }->[0];
$tot_rss += $stats{ "otranpost" }->[1];

$stats{ "otxserv" } = &sumrss( "$cmdpath/ps_otxserv.sh" );
$ps_cnt += $stats{ "otxserv" }->[0];
$tot_rss += $stats{ "otxserv" }->[1];

$stats{ "posapisrv" } = &sumrss( "$cmdpath/ps_posapisrv.sh" );
$ps_cnt += $stats{ "posapisrv" }->[0];
$tot_rss += $stats{ "posapisrv" }->[1];

$stats{ "txrep" } = &sumrss( "$cmdpath/ps_txrep.sh" );
$ps_cnt += $stats{ "txrep" }->[0];
$tot_rss += $stats{ "txrep" }->[1];

my $time = `date '+%Y%m%d %H:%M:%S'`;

print ( $time );
printf( "%10s: %5d %9d\n", "crdtmon", $stats{ "crdtmon" }->[0], $stats{ "crdtmon" }->[1] );
printf( "%10s: %5d %9d\n", "otranpost", $stats{ "otranpost" }->[0], $stats{ "otranpost" }->[1] );
printf( "%10s: %5d %9d\n", "otxserv", $stats{ "otxserv" }->[0], $stats{ "otxserv" }->[1] );
printf( "%10s: %5d %9d\n", "posapisrv", $stats{ "posapisrv" }->[0], $stats{ "posapisrv" }->[1] );
printf( "%10s: %5d %9d\n", "txrep", $stats{ "txrep" }->[0], $stats{ "txrep" }->[1] );
print ( "            _____ _________ ____________________\n" );
printf( "            %5d %9d [mem+swp: %9d]\n", $ps_cnt, $tot_rss, ($mem_used + $swp_used) );
print ( "\n" );


#----- sumrss -----------------------------------------------------------
# Sum the rss for a given "ps_" command.
sub sumrss {
	my $cmd = shift;

	my @output = `$cmd`;
	my @result = ( 0, 0 );

	foreach (@output) {
		my @line = split( /\s+/ );
		$result[0]++; 			#ps_cnt
		$result[1] += $line[3];	#tot_rss
	}
	
	return \@result;
}


exit( 0 );
