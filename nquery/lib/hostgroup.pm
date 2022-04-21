package lib::hostgroup;

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::objectcache;
use lib::statusdat;

use strict;



#----- listCusts ----------------------------------------------------------------
# Parameters ()
# Returns array of customer IDs from the Nagios "hostgroup" records.
sub listCusts {
	my $ds = lib::objectcache::getDefineRecs( "hostgroup" ); 
	my @custlist = ();

	foreach my $rhash (@$ds) {
		# Add to list if it's a top-level group:
		if ($rhash->{'hostgroup_name'} !~ /-/) {
			push( @custlist, $rhash->{'hostgroup_name'} );
		}
	}

	return @custlist;
}



#----- listEnv ----------------------------------------------------------------
# Parameters ()
# Returns array of environment IDs from the Nagios "hostgroup" records.
sub listEnv {
	my $ds = lib::objectcache::getDefineRecs( "hostgroup" ); 
	my %tmphsh;	
	my @envlist = ();

	foreach my $rhash (@$ds) {
		# Add to list if it's a non-top-level group:
		if ($rhash->{'hostgroup_name'} =~ /-/) {
			# Get just the env element of the name:
			my @tmpary = split( /-/, $rhash->{'hostgroup_name'} );
			# Load env element as hash keys to get a list of only unique values
			$tmphsh{$tmpary[1]} = "";
		}
	}
	# Transfer the hash keys into a list and return it.
	for my $key ( keys(%tmphsh) ) {
		push( @envlist, $key );
	}
	return @envlist;
}




#----- listTypes ----------------------------------------------------------------
# Parameters ()
# Returns array of host types from the Nagios "hostgroup" records.
sub listTypes {
	my $ds = lib::objectcache::getDefineRecs( "hostgroup" ); 
	my %tmphsh;	
	my @typelist = ();

	foreach my $rhash (@$ds) {
		# Add to list if it's a non-top-level group:
		if ($rhash->{'hostgroup_name'} =~ /-/) {
			# Get just the type element of the name:
			my @tmpary = split( /-/, $rhash->{'hostgroup_name'} );
			# Load env element as hash keys to get a list of only unique values
			if ($#tmpary == 2) {
				$tmphsh{$tmpary[2]} = "";
			}
		}
	}
	# Transfer the hash keys into a list and return it.
	for my $key ( keys(%tmphsh) ) {
		push( @typelist, $key );
	}
	return @typelist;
}



#----- listHosts -------------------------------------------------------------
# Parameters: (criteria)
# The criteria parameter is a hashref containing the following possible keys:
#    'cust'
# The function will produce a list of hosts. If the 'cust' parameter is
# supplied in the criteria hash, the list consists of hosts for the
# specified host only.
sub listHosts {
	my $criteria = shift;

	my $ds = lib::objectcache::getDefineRecs( "hostgroup" ); 
	my @hostlist = ();


#	print "DEBUG criteria:\n";
#	for my $key ( keys(%$criteria) ) {
#		print $key . " = " . $criteria->{$key} . "\n";
#	}


	foreach my $rhash (@$ds) {
		# Get members for the lop-level groups only:
		if ($rhash->{'hostgroup_name'} !~ /-/) {
			my @hosts;
			if ($criteria->{'cust'}) {
				if ($rhash->{'hostgroup_name'} eq $criteria->{'cust'}) {
					# Load this customer's hosts only, then exit the loop
					@hosts = split( /,/, $rhash->{'members'} );
					foreach my $host (@hosts) {
						push( @hostlist, $host );
					}
				} else {
					next;
				}
			} else {
				# Load all hosts
				@hosts = split( /,/, $rhash->{'members'} );
				foreach my $host (@hosts) {
					push( @hostlist, $host );
				}
			}
		}
	}

	# The 'ip' and 'info' criteria are mutually exclusive: 'info' takes precedence.
	if (exists $criteria->{'ip'} and ! exists $criteria->{'info'}) {
		$ds = lib::objectcache::getDefineRecs( "host" ); 
		foreach my $rhash (@$ds) {
			for (my $i=0; $i<=$#hostlist; $i++) {
				if ($rhash->{'host_name'} eq $hostlist[$i]) {
					$hostlist[$i] .= " ".$rhash->{'address'};
					last;
				}
			}
		}
	}

	if (exists $criteria->{'info'}) {
		$ds = lib::objectcache::getDefineRecs( "host" ); 
		my @stats = lib::statusdat::getStatus();
		foreach my $rhash (@$ds) {
			for (my $i=0; $i<=$#hostlist; $i++) {
				if ($rhash->{'host_name'} eq $hostlist[$i]) {
					$hostlist[$i] .= ",".$rhash->{'address'}.",".$rhash->{'alias'};
					# Gather status summary for this host and its services:
					# Might be useful to rethink this structure and make it more dynamic.
					# (Perhaps two static lists of directives, one for host and one for
					# service which define the members of a hash.)
					my $hoststate = 0;
					my $servstate = 0;
					my $hostack = 0;
					my $servack = 0;
					my $hostmaint = 0;
					my $servmaint = 0;
					foreach my $rec (@stats) {
						if ( $rec->{'host_name'} eq $rhash->{'host_name'} ) {
							if ($rec->{'firstline'} =~ /host/) {
								$hoststate = $rec->{'current_state'};
								$hostack = $rec->{'problem_has_been_acknowledged'};
								$hostmaint = $rec->{'scheduled_downtime_depth'};
							}
							if ($rec->{'firstline'} =~ /service/) {
								if ($rec->{'current_state'} > $servstate) {
									# Only include this service's current_state 
									# in the aggregate if notifications are 
									# enabled.
									if ($rec->{'notifications_enabled'} == 1) {
										$servstate = $rec->{'current_state'};
									}
								}
								if ($rec->{'problem_has_been_acknowledged'} > $servack) {
									$servack = $rec->{'problem_has_been_acknowledged'};
								}
								if ($rec->{'scheduled_downtime_depth'} > $servmaint) {
									$servmaint = $rec->{'scheduled_downtime_depth'};
								}
							}
						}
					}
					$hostlist[$i] .= ",".$hoststate.",".$servstate;
					$hostlist[$i] .= ",".$hostack.",".$servack;
					$hostlist[$i] .= ",".$hostmaint.",".$servmaint;
					last;
				}
			}
		}

	}
	
	return @hostlist;
}


1;
