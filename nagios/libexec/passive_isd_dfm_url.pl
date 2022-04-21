#!/usr/bin/perl

##############################################################################
#
# Name:    check_isd_dfm_url.pl
# Purpose: Logs into the ISD Web UI and parses the "Deposit File Maintenance"
#          screen to determine if settlement has completed for the current 
#          day. Also checks for error condidtions.
#
# Note:    This is a passive service check to be run from cron as needed.
#          See the crontab for the "nagios" user.
#
# $Id: passive_isd_dfm_url.pl,v 1.4 2009/10/02 15:23:33 evaughn Exp $
# $Date: 2009/10/02 15:23:33 $
#
##############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use URI;
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use Time::Local;

use ArgParse;
use CheckLib;




#----- today ------------------------------------------------------------------
# Return today's date as M/D/YY to match the date string on the ISD web ui
sub today {
	my $day;
	my $mon;
	my $yr;
	($day, $mon, $yr) = (localtime)[3,4,5];
	$mon++;
	$yr -= 100;
	my $result = sprintf "%d/%d/%02d", $mon, $day, $yr;
	return $result;
}




#----- Globals ----------------------------------------------------------------
my %args;
my $cmd          = 'cat /proc/meminfo'; # Command to run, arguments and all (see below for more details on this)
my $basedir      = '/u01/home/nagios/monitoring';
my $optstr       = 'I:H:C:S:t:';
my $usage        = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;  # HashRef of properties from the threshold file.
my @required     = ( "username", "password" );

my $tmpfile      = "/tmp/check_isd_dfm-" . `date "+%s"`;
my $today        = today();

# Output variables
my $result;
my $return_code;



#----- main -------------------------------------------------------------------
ArgParse::getArgs( $optstr, 5, \%args, \$usage );

# Populate the passive submit_check with known constants "hostname" and "service"
my $submit_result = "/u01/app/nagios/libexec/submit_check_result.sh $args{H} \"$args{S}\" ";


# Piece-together the name of the thresholds and default files from args:
my $serv_desc = CheckLib::normalizeServDesc( $args{S} );
my $threshold_file = "$basedir/$args{C}/$args{H}-$serv_desc";
if (! -e $threshold_file) {
	# No thresholds file, try default:
	$threshold_file = "$basedir/default/$serv_desc";
}

# Load threshold properties:
$thresholds = CheckLib::loadThresholds( $threshold_file, \@required );
if ($thresholds->{result} ne "0|OK") {
	($return_code,$result) = split( /\|/, $thresholds->{result} );
	print `$submit_result $return_code "$result"`;
	print $result;
	exit $return_code;
}

# Hard-coded threshold defaults:
$thresholds->{port}           = "9035" if (!exists( $thresholds->{port} ));
$thresholds->{base_url}       = "/isdwebui/login.jsp" if (!exists( $thresholds->{base_url} ));
$thresholds->{settlement_url} = "/isdwebui/displaySettlementStartAndStop.html" if (!exists( $thresholds->{settlement_url} ));
$thresholds->{dfm_url}        = "/isdwebui/displayDepositFileMaintenance.html" if (!exists( $thresholds->{dfm_url} ));


# Step 1: Instantiate core objects and configure them
my $ua = LWP::UserAgent->new;
$ua->timeout( $args{t} );
# Turn on cookies and give it an in-memory temp cookie jar
$ua->cookie_jar( {} ); 
push( @{$ua->requests_redirectable}, 'POST' );
my $response;

# Step 2: Query the login URL: this assigns us a session ID, etc.
my $base_request = HTTP::Request->new( GET => 'http://' . $args{I} . ':' . $thresholds->{port} . $thresholds->{base_url} );
$response = $ua->request( $base_request );
if (!$response->is_success) {
	# Request failed.  Could be for a number of reasons (404, conection refused, etc. etc. etc.)
	$result = 'Base ISD Login URL Failed: ' . $response->status_line;
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}

# Step 3: Extract the form action
my $form_action;
if (${$response->content_ref} !~ /action="(.*)"\s/) {
	$result = sprintf 'Unable to find form action tags in %s (Port %d)', $thresholds->{base_url}, $thresholds->{port};
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}

# Step 4: Log in to the ISD webui
$form_action = $1;
my $post_url = sprintf 'http://%s:%d%s', $args{I}, $thresholds->{port}, $form_action;
my $post_request = POST $post_url,[j_username => $thresholds->{username},j_password => $thresholds->{password},j_uri => '',login => 'Login'];
$response = $ua->request( $post_request );
if (!$response->is_success) {
	$result = 'Failed to login: ' . $response->status_line;
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
} elsif (${$response->content_ref} !~ /logged in successfully/i) {
	# In addition to detecting whether or not the page came back OK, parse the
	# output and check if the username/password was accepted or not. We have to
	# parse the content of the page to determine this; the HTTP status code
	# is a 200 whether we authenticate OK or not.
	$result = 'Failed to login: Incorrect Username/Password';
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}


# Step 5: Query the "Deposit File Maintenance" URL
# The content HTML will be saved to a file so we can parse each line separately.
my $dfm_request = HTTP::Request->new( GET => 'http://' . $args{I} . ':' . $thresholds->{port} . $thresholds->{dfm_url} );
$response = $ua->request( $dfm_request, $tmpfile );

if (!$response->is_success) {
	$result = 'Failed to query Settlement URL: ' . $response->status_line;
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}

if (!open( HTML, "<$tmpfile" )) {
#if (!open( HTML, "</tmp/check_isd_dfm_test.html" )) {
	$result = 'Unable to open file ' . $tmpfile . ' to parse HTML output: ' . $!;
	$return_code = 3;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}

my $last_date = "00/00/00";
my $last_time = "00:00";
my $settlement_ran = 0;
my $in_rec = 0;
my $bank_name;
while (<HTML>) {

#if ($in_rec) {
#		# DEBUG
#		print;
#	}

	if ($_ =~ m|<td.*(\d{1,2}?/\d{1,2}?/\d{2,2}?)\s(\d{1,2}?:\d{2,2}?)| && $in_rec) {
		# Finished parsing the first record. Exit loop.
 		last;
	}

	if ($_ =~ m|<td.*>\s*(\d{1,2}?/\d{1,2}?/\d{2,2}?)\s(\d{1,2}?:\d{2,2}?)| && !$in_rec) {
		# Found the first record. Compare date ...
		$in_rec = 1;
		$last_date = $1;
		$last_time = $2;
		if ($last_date eq $today) {
			$settlement_ran = 1;
		}
	}

	# Get the bank name for the current table row:
	if ($_ =~ /<td.*bankButtonClicked.*> *(.*)<\/td>/) {
		$bank_name = $1;
	}
	
	# Check within the first record for various reported errors:
	if (($_ =~ /[Tt]ransmission Error/) && ($bank_name ne "Faux Bank")) {
		$result = "Settlement failed with transmission errors $today";
		$return_code = 2;
		print `$submit_result $return_code "$result"`;
		exit $return_code;
	}
}
close( HTML );
`rm -f $tmpfile`;

if (!$settlement_ran) {
	$result = "Settlement has not completed for today $today. Last Settlement run at [$last_date $last_time]";
	$return_code = 2;
	print `$submit_result $return_code "$result"`;
	exit $return_code;
}

$result = "Settlement ran successfully at [$last_date $last_time]";
$return_code = 0;
print `$submit_result $return_code "$result"`;
exit $return_code;
