#!/usr/bin/perl

my $sar = `which sar`;
my $warning = 80;
my $critial = 90;
chomp($sar);
if (-e $sar) {
	my $line;
	open(CMD,"$sar 1 5|") || exit 3;
	while(<CMD>) {
		$line = $_;
	}
	close(CMD);
	my @vals = reverse(split(/\s+/,$line));
	my $cpu = $vals[0];
	if ($cpu =~ /^\d{1,3}($|\.\d{2})/) {
		$cpu = sprintf("%0.f",$cpu);
		$cpu = 100 - $cpu;
		if ($cpu < $warning) {
			print "OK: CPU Usage $cpu%|$cpu";
			exit 0;
		} elsif ($cpu > $warning && $cpu < $critical) {
			print "WARNING: CPU Usage $cpu%|$cpu";
			exit 1;
		} else {
			print "CRITICAL: CPU Usage $cpu%|$cpu";
			exit 2;
		}
	} else {
		print "UNKNOWN: Invalid SAR output";
		exit 3;
	}
} else {
	print "UNKNOWN: SAR not found";
	exit 3;
}
