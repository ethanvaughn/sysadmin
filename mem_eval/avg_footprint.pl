#!/usr/bin/perl
 
use strict;

if ($#ARGV != 0) {
	&usage_exit;
}
 
my $logfile = $ARGV[0];

my %memdata;

my @list = `cat $logfile | tail -n+5 | sort -k3 -n | tr -s " "`;
my $line;
my $proc_cnt = 0;
my $tot_rss = 0;
my $avg_rss = 0;
foreach $line (@list) {
	my @fields = split( / /, $line );

	my $num_ps = $fields[2];
	my $mem_used = $fields[7];
	
	# Gather up total rss and total proc_cnt to get avg_rss globally:
	$proc_cnt = $proc_cnt + $num_ps;
	$tot_rss = $tot_rss + $fields[5];

	# Populate dataset. key -> num_procs, [0] -> cnt, [1] -> tot_rss, [2] -> avg_rss
	if ($memdata{ $num_ps }) {
		# increment the count field
		$memdata{ $num_ps }->[0]++;
		
		# increment the mem_used sum field
		$memdata{ $num_ps }->[1] += $fields[7];
		
		# update the avg mem_used field
		$memdata{ $num_ps }->[2] = ($memdata{ $num_ps }->[1] / $memdata{ $num_ps }->[0]);

	} else {
		# save ititial count, sum, avg to the hash
		$memdata{ $num_ps } = [1, $fields[7], $fields[7]];
	}
}

my $key;
my $min = 999;
my $max = 1;
foreach $key (sort {$a <=> $b} keys %memdata) {
	# Save min and max:
	if ($key < $min) {
		$min = $key;
	}
	if ($key > $max) {
		$max = $key;
	}
	
	my $val = $memdata{$key};
	if (ref( $val )) {
		printf( "%5d %5d %9d %12.2f\n", $key, $val->[0], $val->[1], $val->[2]);
	}
}

print "\n";

print "Min/Max\n";
printf( "%5d %5d %9d %12.2f\n", $min, $memdata{$min}->[0], $memdata{$min}->[1], $memdata{$min}->[2] );
printf( "%5d %5d %9d %12.2f\n", $max, $memdata{$max}->[0], $memdata{$max}->[1], $memdata{$max}->[2] );

print "\n";

my $avg_per_proc = ($memdata{$max}->[2] - $memdata{$min}->[2]) / $max;
printf( "Avg Mem/Proc: [%12.2f]\n", $avg_per_proc );
 
printf( "Avg RSS/Proc: [%12.2f]\n", ($tot_rss / $proc_cnt) ); 

print "\n";


#----- usage_exit -----------------------------------------------
sub usage_exit {
	print "\n";
	print "Usage: avg_footprint.pl logfile\n";
	print "\n";
	print "The log file must be of the following structure:\n";
	print "\$fields[0] -> date\n";
	print "       [1] -> time\n";
	print "       [2] -> num_procs\n";
	print "       [3] -> avg_rss\n";
	print "       [4] -> 'kB'\n";
	print "       [5] -> tot_rss\n";
	print "       [6] -> 'kB'\n";
	print "       [7] -> mem_used\n";
	print "       [8] -> 'kB'\n";
	print "\n";
	exit( 1 );
}
