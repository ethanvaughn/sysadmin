package lib::time;
use strict;

use Time::Local;

use FindBin qw( $Bin );
use lib "$Bin/..";

#----- now ----------------------------------------------------------------
# Arguments: none
# Returns timestamp string in the form 'YYYY-MM-DD HH:MM:SS' suitable for
# use in database timestamp fields during insert/update.
sub now {
	my @now = localtime();
	return sprintf ("%s-%02s-%02s %02s:%02s:%02s", $now[5]+=1900, $now[4], $now[3], $now[2], $now[1], $now[0]);
}


#----- now_epoch ----------------------------------------------------------------
# Arguments: none
# Returns epoch seconds for current time.
sub now_epoch {
	return timelocal( localtime() );
}



# ----- time_epoch -----------------------------------------------------------
# Takes a time string in format: "YYYY-MM-DD HH:MM:SS" and 
# returns epoch seconds.
sub time_epoch {
	my $time_str = shift;
	my ($yyyy, $mm, $dd, $h, $m, $s);
	($yyyy, $mm, $dd, $h, $m, $s) = $time_str =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
	return timelocal( $s, $m, $h, $dd, ($mm - 1), $yyyy );
}




1;
