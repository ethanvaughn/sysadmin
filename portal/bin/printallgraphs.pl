#!/usr/bin/perl

use strict;

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::createHTML;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MLDBM qw(DB_File);
use Fcntl;
use lib::auth;
 
#--- GLOBALS -------------------------------------------------------------------
my $q = new CGI();
my %graphwest;
my %graphsouth;
my $westgrapharrayofhashes;
my $southgrapharrayofhashes;
my $portal_username = $q->cookie( 'tomaxportalusername' );
my $password        = $q->cookie( 'tomaxportalusername' );
my $nagios_username = $q->cookie( 'tomaxportalcustomer' );
my $upperusername = "\U$nagios_username";
my @sortedarray;

# Authenticate or die.
if (!lib::auth::isValidUser( $portal_username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}

#readWestTree();
readSouthTree();
sendOutput();

sub readWestTree {
	my $dclocation = "west";
  my $westobj;
  my $westfile = "/u01/app/portal/lib/graphtreewest";
  tie( %graphwest, "MLDBM", $westfile, O_RDONLY, 0666, ) || die "Cannot open $westfile\n";

  if ( exists ( $graphwest{$upperusername} ) ) {
    $westobj = $graphwest{$upperusername};
		recursiveReadHash( $westobj, $dclocation );
  } else {
    $westobj = undef;
  }
  untie( %graphwest );
}

sub readSouthTree {
	my $dclocation = "south";
  my $southobj;
  my $southfile = "/u01/app/portal/lib/graphtreesouth";
  tie( %graphsouth, "MLDBM", $southfile, O_RDONLY, 0666, ) || die "Cannot open $southfile\n";

  if ( exists ( $graphsouth{$upperusername} ) ) {
    $southobj = $graphsouth{$upperusername};
		recursiveReadHash( $southobj, $dclocation );
  } else {
    $southobj = undef;
  }
  untie( %graphsouth );
}

sub recursiveReadHash {
	my ( $object, $dclocation ) = @_;
	if ( ref ( $object ) eq "HASH" ) {
		foreach my $child ( @{$object->{children}} ) {
			if ( $child eq "" ) {
				next;
			}
			if ( exists ( $child->{children} ) ) {
				recursiveReadHash( $child, $dclocation );
			} else {
				my %temphash;
				$temphash{name} = $child->{name};
				$temphash{gid} = $child->{gid};
				
				# If the datacenter location of the image is the west datacenter,
				# create a hash value (i.e. true).
				# If the datacenter is not the west datacenter, create undef hash value
				if ( $dclocation eq "west" ) {
					$temphash{location} = $dclocation;
				} else {
					$temphash{location} = undef;
				}
				push ( @sortedarray, \%temphash );
			}
		}
	}
}

sub by_graph_name {
	# Combined graphs (i.e, RAT CPU Usage, RAT JVM Stuff..) should
	# always go above RAT01 - Blah - Foo graphs.  Then sorted normally
	if ($a->{name} =~ /^(\w+) - .* - (.*$)/o && $b->{name} =~ /^(\w+) - .* - (.*$)/) {
		return $a->{name} <=> $b->{name};
	} elsif ($a->{name} =~ /^(\w+) - .* - (.*$)/ && $b->{name} !~ /^(\w+) - .* - (.*$)/) {
		return 1;
	} elsif ($a->{name} !~ /^(\w+) - .* - (.*$)/ && $b->{name} =~ /^(\w+) - .* - (.*$)/) {
		return -1;
	} else {
		return $a->{name} <=> $b->{name};
	}
}

@sortedarray = sort by_graph_name ( @sortedarray );

sub sendOutput {
	lib::createHTML::newTemplate( 'showlistcactigraphs', 'Performance Report List', [ $q, \@sortedarray, $portal_username ] );
}
