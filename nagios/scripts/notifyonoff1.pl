#!/usr/bin/perl
#
#       notifyonoff.pl - S05232006E
#	Called by notifyonoff email alias.
#	Correctly formatted email message is sent to notifyonoff email
#	  address by notify.pl on client machines.	
#

use lib '/u01/app/nagios/scripts';

use strict;
use Net::SMTP;
use HostToGroup;

my ($host,$hostgroup,$source,$service,$action,$switch,$host_grp,$source_grp,$customer,$subject,$message);
my $nagioscmd='/u01/app/nagios/var/rw/nagios.cmd';
my $groupfile='/u01/app/nagios/etc/hostgroups.cfg';

### Main Body

readInMessage();
#validateMessage();
#sendToNagios();
#sendNotifications();
#updatePortal();
#LogIt();


sub readInMessage {

  # The notifyonoff email address pipes the entire email message to this
  # script. We read the message a line at a time from stdin and look for
  # tokens that were sent in the message followed by the data for that token. 
  while(<STDIN>) {

	# $host. The hostname of the machine for which the request was sent. 
	if (/^HOST:/) {
		$_ =~ s/HOST: //;
		$host=$_;
		chomp ($host);
		next;
	}

	# $hostgroup. The name of the hostgroup for which the request was sent. 
	if (/^HOSTGROUP:/) {
		$_ =~ s/HOSTGROUP: //;
		$hostgroup=$_;
		chomp ($hostgroup);
		next;
	}

	# $source. The hostname of the machine sending the request. 
	# Used for validation.
	if (/^SOURCE:/) {
		$_ =~ s/SOURCE: //;
		$source=$_;
		chomp ($source);
		next;
	}

	# $service. The name of the service for which the request was sent. 
	# Notifications for individual services cannot be en/disabled by 
	# hostgroup. This feature is only available by individual host.  
	if (/^SERVICE:/) {
		$_ =~ s/SERVICE: //;
		$service=$_;
		chomp ($service);
		next;
	}

	# $action. The main command to send to Nagios. $host, $hostgtoup
	# and $service are added to this command as needed to complete the
	# syntax required by the command. 
	if (/^ACTION:/) {
		$_ =~ s/ACTION: //;
		$action=$_;
		chomp ($action);
		next;
	}
  }

my ($switch);

 while(<$action>) {
	$_ =~ s/ENABLE //;
	$switch=$_;
	next;
}


#  $switch =~ [a-z]*;
#  $switch =~ /^[a-z]* ($action)/;
#  $switch =~ s/^[_\]$* ($action)//;
#$action=~ /^[a-z]*/;

#my $switch =~ s#($action)#^[a-z]*#;
#my $switch="HEllo";
#$action =~ s/^[_]//;

print "action=$action\n";
print "switch=$switch\n";









}


sub validateMessage {

  # $host_grp. The hostgroup of $host according to Nagios hostgroups.cfg 
  # $source_grp. The hostgroup of $souce according to Nagios hostgroups.cfg

  if (!$host && !$hostgroup) {
	exit 0; #Host or Hostgroup was missing
  }

  if ($source) {
 	$source_grp = mapHostToGroup($source,"$groupfile");
	if (!$source_grp) {
		 exit 0; #source_grp could not be found in hostgroups.cfg
	} 
  }
  if ($host) {
	$host_grp = mapHostToGroup($host,"$groupfile");
	$customer=$host_grp; #We need this variable to notify the correct DBA group
	if (!$host_grp) {
		exit 0; #host_grp could not be found in hostgroups.cfg
	}
	if ($host_grp ne $source_grp) {
		exit 0; #host_grp and source_grp do not match"
	}
  } 
  if ($hostgroup) {
	$customer=$hostgroup; # We need this variable to notify the correct DBA group 
	if (!isGroup($hostgroup,$groupfile)) {
		exit 0; #invalid hostgroup
 	}
 	if ($hostgroup ne $source_grp) {
		exit 0; #hostgroup and source_grp do not match
	} 
  }
}


sub sendToNagios {

  # The Nagios command requires the date in this format.
  my $now=time();

  # Open the Nagios named pipe
  open(NAGPIPE,">>$nagioscmd") || die "Unable to open $nagioscmd: $!";


  # This will en/disable notifications for all services on a host.
  if ($action eq "ENABLE_HOST_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOST_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host\n";
	$subject="$host service notifications";
	$message="Service notifications for host $host have been BLANKED";

  # This will en/disable notifications for all services for all hosts in 
  # the hostgroup specified.
  } elsif ($action eq "ENABLE_HOSTGROUP_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOSTGROUP_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$hostgroup\n";
	$subject="$hostgroup service notifications";
	$message="Service notifications for hostgroup $hostgroup have been BLANKED";

  # This will en/disable notifications for the service specified on 
  # the host specified.
  } elsif ($action eq "ENABLE_SVC_NOTIFICATIONS" || $action eq "DISABLE_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host;$service\n";
	$subject="$host $service notifications";
	$message="Notifications for $service on host $host have been BLANKED";
  }	

  close (NAGPIPE);

}


sub sendNotifications {

  # Use nifty email aliases to notify the correct people.

  my $smtp = Net::SMTP->new('10.24.74.9') || die $?;
  $smtp->mail("noreply\@tomax.com");
 # $smtp->to("dba-$customer-email\@localhost");
  $smtp->to('sevans@tomax.com');
  $smtp->data();
  $smtp->datasend("From: noreply\@tomax.com\n");
  $smtp->datasend("Subject: $subject\n");
  $smtp->datasend("\n$message\n");
  $smtp->datasend("Customer=$customer\n");
  $smtp->dataend();
  $smtp->quit();
 }


sub logIt {

  # Log all of this stuff so we can look up the maintenance windows. We may 
  #   even want to log the invalid requests.

}


sub updatePortal {

  # If we are going to update portal, what kind of information are we
  #   going to send and when? Knowing the customer will probably be
  #   important here.

}
