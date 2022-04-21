#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::statusdat;

use strict;

#----- Main ------------------------------------------------------------------
#Globals
my $show = 0;
if ($ARGV[0] eq 'show') {$show = 1};
my $success = 1;
my $failure = 0;

# Control structures:

my %info = (
	firstline => "info {",
	created => "1156199687",
	version => "2.5",
	lastline => "}"
);

my %program = (
	firstline => "program {",
	modified_host_attributes => "0",
	modified_service_attributes => "0",
	nagios_pid => "27394",
	daemon_mode => "1",
	program_start => "1156197812",
	last_command_check => "1156199686",
	last_log_rotation => "0",
	enable_notifications => "1",
	active_service_checks_enabled => "1",
	passive_service_checks_enabled => "1",
	active_host_checks_enabled => "1",
	passive_host_checks_enabled => "1",
	enable_event_handlers => "1",
	obsess_over_services => "1",
	obsess_over_hosts => "0",
	check_service_freshness => "1",
	check_host_freshness => "1",
	enable_flap_detection => "1",
	enable_failure_prediction => "1",
	process_performance_data => "1",
	global_host_event_handler => "",
	global_service_event_handler => "",
	lastline => "}"
);

my %apps1 = (
	firstline => "host {",
	host_name => "apps1",
	modified_attributes => "1",
	check_command => "check_icmp",
	event_handler => "ca-sd-portal-host!PA",
	has_been_checked => "1",
	should_be_scheduled => "0",
	check_execution_time => "0.063",
	check_latency => "0.000",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	plugin_output => "PING OK - Packet loss = 0%, RTA = 49.87 ms",
	performance_data => "",
	last_check => "1155840039",
	next_check => "0",
	current_attempt => "1",
	max_attempts => "10",
	state_type => "1",
	last_state_change => "1155025410",
	last_hard_state_change => "1155025410",
	last_time_up => "1155840039",
	last_time_down => "1155022479",
	last_time_unreachable => "0",
	last_notification => "1155025410",
	next_notification => "0",
	no_more_notifications => "0",
	current_notification_number => "0",
	notifications_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	flap_detection_enabled => "1",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_host => "1",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
);

my %apps2 = (
	firstline => "host {",
	host_name => "apps2",
	modified_attributes => "0",
	check_command => "check_icmp",
	event_handler => "ca-sd-portal-host!PA",
	has_been_checked => "1",
	should_be_scheduled => "0",
	check_execution_time => "0.076",
	check_latency => "0.000",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	plugin_output => "PING OK - Packet loss = 0%, RTA = 63.43 ms",
	performance_data => "",
	last_check => "1155987837",
	next_check => "0",
	current_attempt => "1",
	max_attempts => "10",
	state_type => "1",
	last_state_change => "1155025423",
	last_hard_state_change => "1155025423",
	last_time_up => "1155987837",
	last_time_down => "1155022685",
	last_time_unreachable => "0",
	last_notification => "1155025423",
	next_notification => "0",
	no_more_notifications => "0",
	current_notification_number => "0",
	notifications_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	flap_detection_enabled => "1",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_host => "1",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
);


my %y16u21 = (
	firstline => "host {",
	host_name => "y16u21",
	modified_attributes => "0",
	check_command => "check_ssh",
	event_handler => "ca-sd-portal-host!BJM",
	has_been_checked => "1",
	should_be_scheduled => "0",
	check_execution_time => "0.126",
	check_latency => "0.000",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	plugin_output => "SSH OK - Sun_SSH_1.0.1 (protocol 2.0)",
	performance_data => "",
	last_check => "1153231755",
	next_check => "0",
	current_attempt => "1",
	max_attempts => "6",
	state_type => "1",
	last_state_change => "1151363007",
	last_hard_state_change => "1151363007",
	last_time_up => "1153231755",
	last_time_down => "0",
	last_time_unreachable => "0",
	last_notification => "0",
	next_notification => "0",
	no_more_notifications => "0",
	current_notification_number => "0",
	notifications_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	flap_detection_enabled => "1",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_host => "1",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
);


my %apps1cpu = (
	firstline => "service {",
	host_name => "apps1",
	service_description => "CPU Usage",
	modified_attributes => "0",
	check_command => "check_cpu",
	event_handler => "ca-sd-portal-service!PA",
	has_been_checked => "1",
	should_be_scheduled => "1",
	check_execution_time => "5.795",
	check_latency => "0.660",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	current_attempt => "1",
	max_attempts => "3",
	state_type => "1",
	last_state_change => "1155771160",
	last_hard_state_change => "1155771160",
	last_time_ok => "1156199470",
	last_time_warning => "1151441903",
	last_time_unknown => "0",
	last_time_critical => "1155770920",
	plugin_output => "OK: CPU Usage 4%",
	performance_data => "4",
	last_check => "1156199470",
	next_check => "1156199710",
	current_notification_number => "0",
	last_notification => "0",
	next_notification => "0",
	no_more_notifications => "0",
	notifications_enabled => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	flap_detection_enabled => "0",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_service => "0",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
);


my %apps2cpu = (
	firstline => "service {",
	host_name => "apps2",
	service_description => "CPU Usage",
	modified_attributes => "0",
	check_command => "check_cpu",
	event_handler => "ca-sd-portal-service!PA",
	has_been_checked => "1",
	should_be_scheduled => "1",
	check_execution_time => "5.907",
	check_latency => "0.647",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	current_attempt => "1",
	max_attempts => "3",
	state_type => "1",
	last_state_change => "1155971150",
	last_hard_state_change => "1155770816",
	last_time_ok => "1156199470",
	last_time_warning => "1151436863",
	last_time_unknown => "0",
	last_time_critical => "1155971090",
	plugin_output => "OK: CPU Usage 3%",
	performance_data => "3",
	last_check => "1156199470",
	next_check => "1156199710",
	current_notification_number => "0",
	last_notification => "0",
	next_notification => "0",
	no_more_notifications => "0",
	notifications_enabled => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	flap_detection_enabled => "0",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_service => "0",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
	);


my %apps2disk = (
	firstline => "service {",
	host_name => "apps2",
	service_description => "Disk Usage",
	modified_attributes => "0",
	check_command => "check_partitions",
	event_handler => "ca-sd-portal-service!PA",
	has_been_checked => "1",
	should_be_scheduled => "1",
	check_execution_time => "0.721",
	check_latency => "0.530",
	check_type => "0",
	current_state => "0",
	last_hard_state => "0",
	current_attempt => "1",
	max_attempts => "3",
	state_type => "1",
	last_state_change => "1155987885",
	last_hard_state_change => "1155204858",
	last_time_ok => "1156199455",
	last_time_warning => "1153623871",
	last_time_unknown => "0",
	last_time_critical => "1155987825",
	plugin_output => "DISK OK - free space:",
	performance_data => "/=1179MB;1612;1813;0;2015 /u01=32009MB;45850;51581;0;57313 /var=208MB;394;443;0;493",
	last_check => "1156199455",
	next_check => "1156199695",
	current_notification_number => "0",
	last_notification => "0",
	next_notification => "0",
	no_more_notifications => "0",
	notifications_enabled => "0",
	active_checks_enabled => "1",
	passive_checks_enabled => "1",
	event_handler_enabled => "1",
	problem_has_been_acknowledged => "0",
	acknowledgement_type => "0",
	flap_detection_enabled => "0",
	failure_prediction_enabled => "1",
	process_performance_data => "1",
	obsess_over_service => "0",
	last_update => "1156199687",
	is_flapping => "0",
	percent_state_change => "0.00",
	scheduled_downtime_depth => "0",
	lastline => "}"
);


#----- Common ----------------------------------------------------------------
sub chkrec {
	my $rhash = shift;
	my $rcntrl = shift;

	foreach my $key (keys( %$rhash )) {
		($show) && print "  ds:[$key -- $rhash->{$key}]    control:[$key -- $rcntrl->{$key}] \n";
		if ($rcntrl->{$key} ne $rhash->{$key}) {
			return $failure;
		}
	}
	return $success;
}


sub chkctrl {
	my $list = shift;
	
	foreach my $rhash (@$list) {
		($show) && print "$rhash->{firstline}\n";
		# check against the controls:
		if ($rhash->{firstline} =~ /info/) {
			(chkrec( $rhash, \%info )) || return $failure;
		}
		if ($rhash->{firstline} =~ /program/) {
			(chkrec( $rhash, \%program )) || return $failure;
		}
		if ($rhash->{firstline} =~ /host/) {
			if ($rhash->{host_name} eq "apps1") { 
				(chkrec( $rhash, \%apps1 )) || return $failure;
			}
			if ($rhash->{host_name} eq "apps2") { 
				(chkrec( $rhash, \%apps2 )) || return $failure;
			}
			if ($rhash->{host_name} eq "y16u21") { 
				(chkrec( $rhash, \%y16u21 )) || return $failure;
			}
		}
		if ($rhash->{firstline} =~ /service/) {
			if ($rhash->{host_name} eq "apps1") {
				(chkrec( $rhash, \%apps1cpu )) || return $failure;
			}
			if ($rhash->{host_name} eq "apps2" and $rhash->{service_description} =~ /CPU/) {
				(chkrec( $rhash, \%apps2cpu )) || return $failure;
			}
			if ($rhash->{host_name} eq "apps2" and $rhash->{service_description} =~ /Disk/) {
				(chkrec( $rhash, \%apps2disk )) || return $failure;
			}
		}
		
		($show) && print "$rhash->{lastline}\n";
	}

	return $success;
}




#----- Tests ----------------------------------------------------------------
sub t1 {
	my @list = lib::statusdat::getStatus();
	($#list != 7) && return $failure;
	(chkctrl( \@list )) || return $failure;
	return $success;
}
print "[1] Test getStatus()    . . .  ";
t1() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



sub t2 {
	my @list = lib::statusdat::getStatusByHost( "apps2" );
	($#list != 2) && return $failure;
	(chkctrl( \@list )) || return $failure;
	return $success;
}
print "[2] Test getStatusByHost()    . . .  ";
t2() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";




sub t3 {
	my @palist = lib::statusdat::getStatusByCust( "pa" );
	my @bjmlist = lib::statusdat::getStatusByCust( "bjm" );
	($#palist != 4) && return $failure;
	($#bjmlist != 0) && return $failure;
	(chkctrl( \@palist )) || return $failure;
	(chkctrl( \@bjmlist )) || return $failure;
	return $success;
}
print "[3] Test getStatusByCust()    . . .  ";
t3() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";

