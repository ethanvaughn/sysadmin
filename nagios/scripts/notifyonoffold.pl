#!/usr/bin/perl
#
#       notifyonoff.pl - S05232006E
#	Called by notifyonoff email alias.
#	Correctly formatted email message is sent to notifyonoff email
#	  address by notify.pl on client machines.	
#

use strict;
use HostToGroup;

my ($host,$hostgroup,$source,$service,$action);
my $nagioscmd='/u01/app/nagios/var/rw/nagios.cmd';
my $groupfile='/u01/app/nagios/etc/hostgroups.cfg';

### Main Body

#readInMessage();
validateMessage();
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
}


sub sendToNagios {

  # The Nagios command requires the date in this format.
  my $now=time();
  chomp ($now);

  # Open the Nagios named pipe
  open (NAGPIPE, ">$nagioscmd");

  # This will en/disable notifications for all services on a host.
  if ($action eq "ENABLE_HOST_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOST_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host\n";

  # This will en/disable notifications for all services for all hosts in 
  # the hostgroup specified.
  } elsif ($action eq "ENABLE_HOSTGROUP_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOSTGROUP_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$hostgroup\n";

  # This will en/disable notifications for the service specified on 
  # the host specified.
  } elsif ($action eq "ENABLE_SVC_NOTIFICATIONS" || $action eq "DISABLE_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host;$service\n";
  }	

  close (NAGPIPE);

}

sub validateMessage {

my ($host_grp,$source_grp);

$host="u19u13";
$source="v19u30";
#$hostgroup="rat";

    # $host_grp. The hostgroup of $host according to Nagios hostgroups.cfg 
    # $source_grp. The hostgroup of $souce according to Nagios hostgroups.cfg
    my $source_grp = mapHostToGroup($source,"$groupfile");
    if ($host) {
    	my $host_grp = mapHostToGroup($host,"$groupfile");
	if ($host_grp eq $source_grp) {
		print "Valid\nHOST: $host ($host_grp)\n SRC: $source ($source_grp)\n";
	} else {
		print "$source ($source_grp) is not a member of the $host_grp hostgroup\n";
	}
    } elsif ($hostgroup) {
	if (isGroup($hostgroup,$groupfile)) {
		if ($hostgroup eq $source_grp) {
			print "Valid\nHOSTGROUP: $hostgroup\nSRC:$source\nHGRP: $host_grp\nSGRP: $source_grp\n";
  		} else {
			print "Invalid\nHOSTGROUP: $hostgroup\nSRC:$source\nHGRP: $host_grp\nSGRP: $source_grp\n";
			print "$source ($source_grp) is not a member of the $hostgroup hostgroup\n";
			exit 1;
 		} 
  	} else {
		print "$hostgroup is not a valid hostgroup\n"; 
	}
    } 


# } elsif (isGroup($hostgroup,$groupfile)) {
#	valid='Y';
#  }
	


# print "$hostgroup is a group!!\n";
#  } else {
#   print "$hostgroup is not a group :(\n";
#  }


  # We need to lookup customer of $host for sendNotifications and updatePortal
  # If the customer that $source belongs to is eq the customer that $host 
  #   belongs to, then no further validation is required.
  # If $hostgroup is sent, we need to make sure it is a valid hostgroup
  # If the customer that $source belongs to does not match the customer that
  #   $host belongs to, we need to decide what to do. Do we simply exit
  #   and not process the command? Do we log it? Do we notify someone to
  #   let them know that you can only en/disable notifications from servers
  #   in the same hostgroup?
  
}


#sub sendNotifications {

  # Use nifty email aliases to notify the correct people.
  # Knowing the customer will be important here.

#}


#sub logIt {

  # Log all of this stuff so we can look up the maintenance windows. We may 
  #   even want to log the invalid requests.

#}


#sub updatePortal {

  # If we are going to update portal, what kind of information are we
  #   going to send and when? Knowing the customer will probably be
  #   important here.

#}
