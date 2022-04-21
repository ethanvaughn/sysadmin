package lib::ack;

###########################################################################################
#
# Purpose:	library functions for ACK UI
#
# $Id: ack.pm,v 1.2 2008/02/20 00:09:42 jkruse Exp $
# $Date: 2008/02/20 00:09:42 $
#
###########################################################################################

use strict;
use threads;
use threads::shared;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

# Config directives

my $timeout :shared = 15;			# Timeout value of each thread
my $post_timeout = 3;				# Timeout when submitting commands
my $oncall_timeout = 3;				# Timeout when querying on-call URL
my $query_url :shared = '/nquery/listunack';	# URL being queried by each thread
my $cmd_url = '/pcgi/ack';
my $passwd = '/etc/passwd';

# Globals

my @problems :shared;

sub queryServers {
	my $server_list_file = shift;
	my $server_list = readServerCFGFile($server_list_file);
	if (ref($server_list) ne 'ARRAY') {
		die 'queryServers: expected array ref as $_[0]';
	}
	my @threads;
	foreach my $server (@$server_list) {
		my $thread = threads->create(\&queryServer,$server);
		push(@threads,$thread);
	}
	# Wait on each thread to finish
	foreach my $thread (@threads) {
		$thread->join();
	}
	# And return the results
	return (\@problems,$server_list);
}

sub queryServer {
	my $server = shift;
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new(GET => 'http://'.$server->{ip}.$query_url);
	$ua->timeout($timeout);
	my $response = $ua->request($req);
	if ($response->is_success) {
		# Update the site object
		$server->{status} = 1;
		# Now parse the problems
		my @input = split(/\n/,${$response->content_ref});
		foreach my $line (@input) {
			my @values = split(/\|/,$line);
			if (scalar(@values) == 7) {
				my %problem :shared;
				if ($values[0] eq 'WARNING') {
					$problem{iswarning} = 1;
				}
				$problem{severity} = $values[0];
				$problem{hostname} = $values[1];
				$problem{hostdesc} = $values[2];
				$problem{hostip} = $values[3];
				if (length($values[5]) > 46) {
					$problem{short_output} = substr($values[5],0,46).'...';
				} else {
					$problem{short_output} = $values[5];
				}
				$problem{long_output} = $values[5];
				# $problem{long_output} will be displayed in another window if the user clicks on the link
				# the problem arises thata standard HTTP GET needs to be URL-encoded (space = %20, and so on)
				# so we store the string URL-encoded here via this regex
				$problem{long_output} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
				$problem{category} = $values[6];
				$problem{nagios_ip} = $server->{ip};	# Store with each problem which server should ACK it
				# Is it a host problem or a service problem?
				# This sets fields that are picked up by the templates
				if ($values[4] eq 'HOST') {
					# Host problem
					$problem{host} = 1;
				} else {	
					# Service problem
					$problem{servicedesc} = $values[4];
				}
				# Lastly lock the problems array, and add this problem to it
				# These braces create a separate scope such that the lock will release
				# (there is no unlock) as soon as the scoped block containing the lock
				# statement completes
				{
					lock(@problems);
					push(@problems,\%problem);
					#print "Adding $problem{hostname}\n";
				}
			}
		}
	} else {
		$server->{status} = 0;
		$server->{error} = $response->status_line;
	}
	
}

sub getUserGroup {
	my ($cfg_file,$user) = @_;
	# If $cfg_file is empty, then error out
	if (!$cfg_file) {
		die 'getUserGroup: expects cfg_filename $_[0],username $_[1]';
	} elsif (!$user) {
		# If no user was set, then just return -- no user could be a result of running
		# from the command line, or a misconfigured web server.  Either way, rather than
		# barf an unsightly error, if we just return undef the caller will think the user
		# isn't authorized, which can be more helpful in troubleshooting than barfing
		# with an undefined variable error
		return;
	}
	my $groups = readGroupCFGFile($cfg_file);
	my $res = open(FILE,$passwd);
	if ($res) {
		my $group_name; # This will be sysadmin,dba,etc.
		while(<FILE>) {
			if (/^$user:x:\d+:(\d+):/) {
				$group_name = $groups->{$1};
				last;
			}
		}
		close(FILE);
		return $group_name;
	} else {
		die 'Unable to open passwd::'.$!;
	}
}

sub readGroupCFGFile {
	my $filename = shift;
	my %groups;
	my $res = open(FILE,$filename);
	if ($res) {
		while(<FILE>) {
			chomp;
			if (/^(\w+):(\d+)$/) {
				$groups{$2} = $1;
			}
		}
		close(FILE);
		return \%groups;
	} else {
		# Unable to open the file.  Bad news
		die 'Unable to open group list: '.$filename.' (Error: '.$!.')';
	}
}

sub readServerCFGFile  {
	my $filename = shift;
	open(FH,$filename) || die $!;
	my @monitoring_servers;
	while(<FH>) {
		chomp;
		if (/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(.*)$/) {
			my %server :shared;
			$server{ip} = $1;
			$server{desc} = $2;
			push(@monitoring_servers,\%server);
		}
	}
	close(FH);
	if (scalar(@monitoring_servers) == 0) {
		die 'No valid servers found in '.$filename
	} else {
		return \@monitoring_servers;
	}
}


sub sendCommands {
	my $commands = shift;
	if (ref($commands) ne 'ARRAY') {
		die 'sendCommands: expects array ref for $_[0]';
	} else {
		my @threads;
		foreach my $cmd (@$commands) {
			my $thread = threads->create(\&sendCommand,$cmd);
			push(@threads,$thread);
		}
		# Wait on each thread to finish
		foreach my $thread (@threads) {
			$thread->join();
		}
	}
}

sub sendCommand {
	my $cmd = shift;
	if (!$cmd) {
		die 'sendCommand($cmd): expected scalar for $_[0]';
	} else {
		# $cmd is a string of key:value comma-separated pairs
		# convert it into an object that we will build an actual Nagios command from
		my $obj = convertStringToObject($cmd);
		my $nagios_command_string; # Will contain the Nagios commands derived from this object
		if ($obj->{action} eq 'ack') {
			# Build an ACK command
			if ($obj->{type} eq 'host') {
				$nagios_command_string.= sprintf(	'ACKNOWLEDGE_HOST_PROBLEM$%s$2$1$0$%s$%s%s',
									$obj->{host},
									$obj->{user},
									'ACK',
									"\n"
								);
			} elsif ($obj->{type} eq 'service') {
				my $sticky;
				if ($obj->{ack_type} eq 'sticky') {
					$sticky = 2;
				} elsif ($obj->{ack_type} eq 'nonsticky') {
					$sticky = 0;
				} else {
					die 'sendCommand($cmd): invalid ack type';
				}
				$nagios_command_string.= sprintf(	'ACKNOWLEDGE_SVC_PROBLEM$%s$%s$%d$1$0$%s$%s%s',
									$obj->{host},
									$obj->{service},
									$sticky,
									$obj->{user},
									'ACK',
									"\n"
								);
			} else {
				# Invalid object type, should never happen!
				die 'sendCommand($cmd): invalid object type'
			}
		} elsif ($obj->{action} eq 'maint') {
			# Counter-intuitive: people actually like ACK pages, and just scheduling a maintenance window
			# will not cause an ACK notification to be sent out.  So, we do the following:
			# 1) ACK the problem
			# 2) Schedule a maintenance window
			# 3) Reset the notification counter
			# 4) Remove the ACK
	
			# Send a non-sticky ACK
			$nagios_command_string.= sprintf(	'ACKNOWLEDGE_SVC_PROBLEM$%s$%s$%d$1$0$%s$%s%s',
								$obj->{host},
								$obj->{service},
								0,
								$obj->{user},
								'ACK_TEMP',
								"\n"
							);
			my $now = time();
			# Schedule the maintenance window
			$nagios_command_string.= sprintf(	'SCHEDULE_SVC_DOWNTIME$%s$%s$%lu$%lu$1$0$%d$%s$%s%s',
								$obj->{host},
								$obj->{service},
								$now,
								$now+3600,
								3600,
								$obj->{user},
								'ACK_MAINT',
								"\n"
							);
			# Reset the notification counter
			$nagios_command_string.= sprintf(	'SET_SVC_NOTIFICATION_NUMBER$%s$%s$%d%s',
								$obj->{host},
								$obj->{service},
								0,
								"\n"
							);
			# Lastly, remove the acknowledgement -- the maintenance window is in place
			# now so the ACK is no longer necessary
			$nagios_command_string.= sprintf(	'REMOVE_SVC_ACKNOWLEDGEMENT$%s$%s%s',
								$obj->{host},
								$obj->{service},
								"\n"
							);
		} else {
			# Valid object actions are ack and maint -- should never happen!
			die 'sendCommand($cmd): invalid object action';
		}
		if ($obj->{server} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
			die 'sendCommand($cmd): no IP address of monitoring server found in $obj';
		} else {
			my $ua = LWP::UserAgent->new();
			$ua->timeout($post_timeout);
			my $req = POST 'http://'.$obj->{server}.$cmd_url,[ cmd => $nagios_command_string ];
			my $response = $ua->request($req);
			if (!$response->is_success) {
				# The request failed: why?
				die 'sendCommand($cmd) failed POST: '.$response->status_line;
			}
		}
	}
}

sub convertStringToObject {
	my $string = shift;
	my %obj;
	my @tokens = split(/,/,$string);
	foreach my $token (@tokens) {
		if ($token =~ /^(.*):(.*)$/) {
			$obj{$1} = $2;
		}
	}
	return \%obj;
}

sub queryOnCallServer {
	my $filename = shift;
	my $res = open(FILE,$filename);
	if (!$res) {
		die $!;
	}
	# $url: the url to query for on-call list
	# $ip: ip address of on-call DB server
	# @data: contains list that user sees in web page (HTML::Template loop structure)
	# %groups: list of groups (display name and on-call group name) read from file
	my ($url,$ip,@data,%groups);
	while(<FILE>) {
		chomp;
		if (/^group:(.*)\|(.*)/) {
			my %h;
			# $1 is the display name (i.e, DBA On-Call)
			# $2 is the name of the actual group (i.e, dba-team1-oncall)
			$groups{$2} = { displayname => $1 };
		} elsif (/^url:(.*)/) {
			$url = $1;
		} elsif (/^ip:(.*)/) {
			$ip = $1;
		}
	}
	close(FILE);
	if (!defined($url) || !defined($ip)) {
		die 'queryOnCallServer($filename): expected url & ip in cfg file,not found';
	}
	# Now query on-call DB based off of what we know
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new(GET => 'http://'.$ip.$url);
	$ua->timeout($oncall_timeout);
	my $response = $ua->request($req);
	if (!$response->is_success) {
		warn('Unable to query on-call DB:'.$response->status_line);
		return \@data; # Just return an empty array ref
	} else {
		foreach my $line (split(/\r\n/,${$response->content_ref})) {
			if ($line =~ /^(.*)\|(.*)$/) {
				# $1: group
				# $2: name/phone
				my $group = lc($1);
                		my $name = $2;
                		$name =~ s/:(\d+)/ \(\1\)/;
				if (exists($groups{$group})) {
					if (exists($groups{$group}->{members})) {
						push(@{$groups{$group}->{members}},$name);
					} else {
						$groups{$group}->{members} = [$name];
					}
				}
			}
		}
		# Each key in %groups points to a hash ref.  The key,
		# which is the actual on-call DB group name, isn't
		# needed anymore -- we need the display name (i.e, DBA OnCall Backup)
		# and the members of said group.  members are a key in this hash ref
		# that points to an array ref.  That said, we use the key to get
		# a sorted array of groups.
		foreach my $key (sort(keys(%groups))) {
			my $obj = $groups{$key};
			my %h; # Construct a new hash to be put in the @data array
			$h{displayname} = $obj->{displayname};
			my $members_string;
			foreach my $member (@{$obj->{members}}) {
				# Yes this is bad form, as now HTML is embedded inside the application.
				# That said, there seemed to be no good way to
				$members_string.= sprintf('%s<br>',$member);
			}
			# Remove the trailing <br> in the string now
			$members_string =~ s/<br>$//;
			$h{members} = $members_string;
			# And add to the @data array
			push(@data,\%h);
		}
		return \@data;
	}
}

1;
