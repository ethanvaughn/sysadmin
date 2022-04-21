#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use CGI;
use Fcntl;
use HTML::Template;
use POSIX qw(mktime);
use MLDBM qw(DB_File);
use CGI::Carp qw(fatalsToBrowser);
use lib::auth;

# Init objects

my $q =				new CGI;
my $customer =		uc($q->cookie('tomaxportalcustomer'));
my $username = 		$q->cookie( 'tomaxportalusername' ); # Used to load customer-specific CSS
my $cgi =			$q->url(-absolute=>1); # Path to self
$CGI::POST_MAX=1024 * 100; # max 100K posts
$CGI::DISABLE_UPLOADS = 1; # no uploads


# Authenticate or die.
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


# Misc Globals
my @graphs;			# List of graphs found in tree (as hash refs)
my $template;		# HTML::Template object
my $graph_file =	'/u01/app/portal/lib/graphtreesouth';
my $basedir =		'/u01/app/portal/html/';

# Parsed user input variables
my @graphs_to_view;	# Graph IDs selected by the user to view
my $from_timestamp;	# Time to start graph from
my $to_timestamp;	# Time to end graph

main();

sub main {
	if (defined($customer)) {
		my $step = $q->param('step');
		if ($step == 1) {
			# The user has selected some graphs to see
			if (allParametersAreValid()) {
				if (dateRangesAreValid()) {
					showCustomReport();
				} else {
					newTemplate('performance_report_invalid_date.html');
				}
			} else {
				# The user is missing one or more parameters
				# Kick them back to the first menu
				showGraphList();
			}
		} else {
			# Main menu, show graphs and time selector
			showGraphList();
		}
	} else {
		# The user doesn't have a cookie
		# Redirect them back to the login page
	}
	makeHTML();
}

sub showGraphList {
	my %tree;
	tie(%tree,'MLDBM',$graph_file,O_RDONLY,0666) || die $!;
	if (exists($tree{$customer})) {
		my $customer_tree = $tree{$customer};
		walkTree($customer_tree);
		@graphs = sort({$a->{name} cmp $b->{name}} @graphs);
		# Graph list is now sorted.  Generate years list
		my $years = generateYears();
		newTemplate('performance_report_1.html');
		$template->param(year => $years);
		$template->param(graphs => \@graphs);
	} else {
		die $customer.' not found in database';
	}
}

sub showCustomReport {
	newTemplate('performance_report_2.html');
	$template->param(from => $from_timestamp);
	$template->param(to => $to_timestamp);
	$template->param(images => \@graphs_to_view);
}

sub dateRangesAreValid {
	# In addition to returning a boolean, this function
	# also sets $from_timestamp and $to_timestamp

	# syntax to the POSIX function mktime is as follows
	#my $unixtime = mktime ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst);
	# We leave $wday and $yday blank, since they aren't necessary based off the other parameters we have.
	# $isdst is set to -1, which means we don't know, and want the underlying C libraries to figure out if
	# the resulting timestamp should be offset by DST or not

	$from_timestamp = mktime(0,0,$q->param('f_hour'),$q->param('f_day'),$q->param('f_month'),$q->param('f_year'),undef,undef,-1);
	$to_timestamp = mktime(0,0,$q->param('t_hour'),$q->param('t_day'),$q->param('t_month'),$q->param('t_year'),undef,undef,-1);
	if ($from_timestamp > 0 && $to_timestamp > 0 && $from_timestamp < $to_timestamp) {
		return 1;
	} else {
		return 0;
	}
}

sub allParametersAreValid {
	my $retval = 0;
	my $parameters_validated = 0;
	my $parameters_to_validate = 7;
	# We have a bunch of parameters to validate!
	# 3 fields for from (month/day/hour)
	if (validateIntegerRange(-1,12,$q->param('f_month'))) {
		$parameters_validated++;
	}
	if (validateIntegerRange(-1,32,$q->param('f_day'))) {
		$parameters_validated++;
	}
	if (validateIntegerRange(-1,24,$q->param('f_hour'))) {
		$parameters_validated++;
	}
	# 3 fields for to (month/day/hour)
	if (validateIntegerRange(-1,12,$q->param('t_month'))) {
		$parameters_validated++;
	}
	if (validateIntegerRange(-1,32,$q->param('t_day'))) {
		$parameters_validated++;
	}
	if (validateIntegerRange(-1,24,$q->param('t_hour'))) {
		$parameters_validated++;
	}
	# Lastly need to validate that the user selected at least one graph
	my $params = $q->Vars();
	my @ids = split("\0",$params->{'graph'});
	foreach my $id (@ids) {
		if ($id =~ /^\d+$/) {
			my %h;
			$h{id} = $id;
			push(@graphs_to_view,\%h);
		}
	}
	if (scalar(@graphs_to_view) > 0) {
			$parameters_validated++;
	}
	if ($parameters_to_validate == $parameters_validated) {
		return 1;
	} else {
		return 0;
	}
}

sub validateIntegerRange {
	my ($low,$high,$value) = @_;
	if ($value > $low && $value < $high) {
		return 1;
	} else {
		return 0;
	}
}

sub generateYears {
	my @date = localtime();
	my $current_year = $date[5];
	my $range = 3;
	my @years;
	for (my $i = $current_year - $range; $i < $current_year + $range; $i++) {
		my %h;
		$h{value} = $i;
		$h{display} = $i+1900;
		if ($i == $current_year) {
			$h{current_year} = 1;
		}
		push(@years,\%h);
	}
	return \@years;
}

sub newTemplate {
	my $filename = shift;
	# Check to make sure we actually got a filename
	$template = HTML::Template->new(filename => $basedir.$filename, loop_context_vars => 1, global_vars => 1);
	$template->param(cgi => $q->url(-absolute=>1)); # CGI Script Name
	$template->param(customer_css => $username); # CGI Script Name
}

sub makeHTML {
	if (!$template) {
		print 'Content-type: text/plain',"\n\n";
		print 'Template not loaded! Contact Tomax SysAdmin team with this error';
	} else {
		# Set content type and setup to allow forward/back in form
		#print 'Cache-Control: private, must-revalidate',"\n";
		print 'Content-type: text/html',"\n\n";
		# Print content
		print $template->output();
	}
	exit 0;
}



sub walkTree {
	my $href = shift;
	die 'Not a hash ref' if ref($href) ne 'HASH';
	if (exists($href->{gid})) {
		# This is a graph, add to @graphs
		push(@graphs,$href);
	} elsif (exists($href->{children})) {
		# This is a leaf
		foreach my $child (@{$href->{children}}) {
			# This is important.  While every child array is ordered,
			# there may not be anything in certain positions of the array
			# If a graph tree used to have graphs 1,2,3,4,5,6, and we delete 1 and 2,
			# 3,4,5,6 will all remain.  Also, order keys always start at 1, and arrays
			# start at 0, so the first position in every child array (index 0) can be skipped
			# To do this universally, just check if this position in the array is actually
			# a hash ref or not, and only process it if it is.  On this if .. statement we do
			# not return, just skip this child and move onto the next.  (Returning would cause
			# all subsequent children to get ignored)
			if (ref($child) eq 'HASH') {
				walkTree($child);
			} 
		}
	} else {
		return;
	}
}


