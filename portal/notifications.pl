#!/usr/bin/perl
use strict;
use CGI;
use HTML::Template;
use CGI::Carp 'fatalsToBrowser';
use lib::auth;

#----- Globals ----------------------------------------------------------
my $q = new CGI;

# Get the cookie values
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );


#----- main --------------------------------------------------------------
# Authenticate or die.
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: login.html',"\n\n";
	exit 0;
}

my $dir = '/u01/app/portal/var/';

my $q = new CGI;
my $username = $q->cookie("tomaxportalusername");
my $customer = $q->cookie("tomaxportalcustomer");
my $ucustomer = uc($customer);
my $template;

newTemplate('notifications', 'Notifications');
$template->param(customer => $ucustomer, username => $username);
$template->param(notifications => readFiles());
makeHTML();

sub readEvent {
	my ($file,$time) = @_;
	my %event;
	$event{'time'} = $time;
	$event{lastupdate} = scalar(localtime($time));
	if (open(FH,$dir.$file)) {
		while(<FH>) {
			chomp;
			if (/(\d),(.*)/) {
				if ($1 == 0) {
					$event{up} = 1;
				} elsif ($1 == 1) {
					$event{warning} = 1;
				} elsif ($1 == 2) {
					$event{critical} = 1;
				} elsif ($1 == 3) {
					$event{unreachable} = 1;
				}
				$event{subject} = $2;
				last;
			}
		}
		close(FH);
		return \%event;
	}
}

sub readFiles {
	my @events;
	if (opendir(DIR,$dir)) {
		foreach my $file (readdir(DIR)) {
			if ($file =~ /^$customer\.\d+-(\d+)$/) {
				my $event = readEvent($file,$1);
				if (ref($event) eq 'HASH') {
					push(@events,$event);
				}
			}
		}
		closedir(DIR);
		# Before returning @events, sort them
		@events = reverse(sort({ $a->{'time'} <=> $b->{'time'} } @events));
		return \@events;
	} else {
		die "Unable to open $dir: $!";
	}
}

sub newTemplate {
  my ($filename,$title) = @_;
  # Check to make sure we actually got a filename
  my $basedir = '/u01/app/portal/html';
  $template = HTML::Template->new(filename => $basedir.'/'.$filename.'.html', die_on_bad_params => 0, loop_context_vars => 1, global_vars => 1);
  $template->param(cgi => $q->url(-absolute=>1)); # CGI Script Name
  $template->param(title => $title);
}

sub makeHTML {
  # Close DB connection, we know we won't need it at this point
  # Set content type, allow caching
  print "Refresh: 300\n";
  print "Cache-Control: private-must-revalidate\n";
  print "Content-type: text/html\n\n";
  print $template->output();
  exit 0;
}
