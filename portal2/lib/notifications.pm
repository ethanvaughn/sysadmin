package lib::notifications;

use FindBin qw( $Bin );
use lib "$Bin";

use lib::conf;

use strict;




#----- readEvents -------------------------------------------------------------
# Returns AoH notification events for customer.
sub readEvents {
	my $cust_code = shift;
	
	my $path = $DATAPATH . "/notifications";

print STDERR "notifications: path = $path\n";

	my @events;
	if (opendir( DIR, $path )) {
		foreach my $file (readdir( DIR )) {
			if ($file =~ /^$cust_code\.\d+-(\d+)$/) {
				my $time = $1; # use the time from the filename
				my $event = parseEvent( $file, $time );
				if (ref($event) eq 'HASH') {
					push (@events, $event );
				}
			}
		}
		closedir(DIR);

		# Reverse sort events by "time" before returning.
		@events = reverse( sort( { $a->{'time'} <=> $b->{'time'} } @events ) );
		
		return \@events;
	} else {
		print STDERR "Unable to open notifications directory $DATAPATH: $!";
	}
}



#----- parseEvent -------------------------------------------------------------
# Helper function to parse the Nagios event info from a file.
# Returns hash of the notification record.
sub parseEvent {
	my $file = shift;
	my $time = shift;

	my $PATH = $DATAPATH . "/notifications";

	my %event;
	$event{time}       = $time;
	$event{lastupdate} = scalar( localtime( $time ) );

	if (!open( FH, "<$PATH/$file" )) {
		print STDERR "notifications.pm: Error opening file [$PATH/$file] for \n";
		return;
	}
	
	while(<FH>) {
		chomp;
		if (/(\d),(.*): (.*)[(](.*)[)]: (.*)/) {
			$event{status}              = $1;
			$event{status_description}  = $2;
			$event{service_description} = $3;
			$event{hostname}            = $4;
			$event{plugin_output}       = $5;
			last;
		}
	}
	close( FH );
	return \%event;
}




1;
