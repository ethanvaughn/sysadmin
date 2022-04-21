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
my $portal_username = $q->cookie( 'tomaxportalusername' );
my $password        = $q->cookie( 'tomaxportalusername' );
my $nagios_username = $q->cookie( 'tomaxportalcustomer' );
my $upperusername = "\U$nagios_username";
my $id = $q->param( 'id' );
my $showimages = $q->param( 'showimages' );
my $showyears = $q->param( 'showyears' );
my $year = $q->param( 'year' );
my %graphwest;
my %graphsouth;
my $westgrapharrayofhashes;
my $southgrapharrayofhashes;
my $years;

# Authenticate or die.
if (!lib::auth::isValidUser( $portal_username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


# West datacenter or South datacenter
my $dclocation = $q->param( 'dclocation' );

# Decide which datacenter to go to.  True (1) for WDC, False (0) for SDC 
# This is different from $dclocation this variable will be used in 
# HTML::Template <tmpl_if name=datacenter> block.  HTML::Template must have the 
# value as either true or false
my $datacenter = 1; 

init();



#---- init----------------------------------------------------------------------
# Call the functions that read the west and south cacti graph hashes.  If the 
# datacenter location has been set, read the corresponding cacti graph hash

sub init {
	$years = readYears();
	if ( defined( $dclocation ) ) {
		if ( $dclocation eq "west" ) {
			readWestTree();
			sendOutput();
		} elsif ( $dclocation eq "south" ) {
			readSouthTree();
			sendOutput();
		}
	} elsif ( defined ( $year ) ) {
		readWestTree();
		readSouthTree();
		sendOutput();
	} else {
		sendOutput();
	}
}


sub readYears {
	my @dircontents;
	my @yeardirectories;
	my $dir = '/u01/app/archived_graphs';
	opendir( DIR, $dir ) || die "Cannot open dir: $dir\n";
	foreach ( readdir( DIR ) ) {
		if ( /^\d{4}$/ ) {
			my %tmphash;
			$tmphash{'year'} = $_;
			push( @yeardirectories, \%tmphash );
		}
	}
	return \@yeardirectories;
}


#---- readWestTree()------------------------------------------------------------
# Read the west cacti hash file

sub readWestTree {
	my $westobj;
	my $westfile = "/u01/app/archived_graphs/$year/wdc/graphtreewest";
	tie( %graphwest, "MLDBM", $westfile, O_RDONLY, 0666, ) || die "Cannot open $westfile\n";

	if ( exists ( $graphwest{$upperusername} ) ) {
		$westobj = $graphwest{$upperusername};
	} else {
		$westobj = undef;
	}
	untie( %graphwest );

	if ( ( $id eq "" ) && ( defined( $westobj ) ) ) {
		$westgrapharrayofhashes = printParentArrayofHashes( $westobj );
	} elsif ( ( $id ne "" ) && ( defined( $westobj ) ) ) {
		$westgrapharrayofhashes = printArrayofHashes( $westobj, $id );
	} else {
		$westgrapharrayofhashes = undef;
	}
}



#---- readSouthTree-------------------------------------------------------------
# Read the south cacti hash file

sub readSouthTree {
	my $southobj;
	my $southfile = "/u01/app/archived_graphs/$year/sdc/graphtreesouth";
	tie( %graphsouth, "MLDBM", $southfile, O_RDONLY, 0666, ) || die "Cannot open $southfile\n";

	if ( exists ( $graphsouth{$upperusername} ) ) {
		$southobj = $graphsouth{$upperusername};
		$datacenter = 0;
	} else {
		$southobj = undef;
	}
	untie( %graphsouth );

	if ( ( $id eq "" ) && ( defined( $southobj ) ) ) {
		$southgrapharrayofhashes = printParentArrayofHashes( $southobj );
	} elsif ( ( $id ne "" ) && ( defined( $southobj ) ) ) {
		$southgrapharrayofhashes = printArrayofHashes( $southobj, $id );
	} else {
		$southgrapharrayofhashes = undef;
	}
}



# ---- sendOutput---------------------------------------------------------------
# Send the data to HTML::Template

sub sendOutput {
	if ( $showyears ) {
		lib::createHTML::newTemplate( 'showyears', 'Archived Graphs', [ $q, $portal_username, $years ] );
	}
	if ( $showimages ) {
		# Because the original author of this application is an idiot we need the below case statement.  In 2007 and later, Cacti just dumps
		# all of the exported graphs to a single folder -- the one folder per customer does not apply (nor is it necessary, with the way this logic works)
		# For a greater understanding of why this is necessary, see the way the genius decided to work the newTemplate function for why this case statement
		# is even necessary.  What an idiot.
		if ($year > 2006) {
			lib::createHTML::newTemplate( 'archiveshowgraphs', 'Archived Performance Reports', [ $q, $showimages, $dclocation, $datacenter, $portal_username, 'graphs', $year ] );
		} else {
			lib::createHTML::newTemplate( 'archiveshowgraphs', 'Archived Performance Reports', [ $q, $showimages, $dclocation, $datacenter, $portal_username, $upperusername, $year ] );
		}
	}
	if ( ( defined ( $westgrapharrayofhashes ) ) && ( defined ( $southgrapharrayofhashes ) ) ) {
		# Go print the page that has a link to the west and south datacenters
		lib::createHTML::newTemplate( 'archive_datacenter', 'Datacenter Location', [ $q, $portal_username ] );
	} elsif ( defined ( $westgrapharrayofhashes ) ) {
		lib::createHTML::newTemplate( 'archived_graphs', 'Archived Graphs', [ $q, $westgrapharrayofhashes, $dclocation, $portal_username, $year ] );
	} elsif ( defined ( $southgrapharrayofhashes ) ) {
		lib::createHTML::newTemplate( 'archived_graphs', 'Archived Graphs', [ $q, $southgrapharrayofhashes, $dclocation, $portal_username, $year] );
	}
}




#---- printParentArrayofHashes -------------------------------------------------
# input: ( $obj )
# return ( $grapharrayofhashes );
# Print the top level tree in the hash (i.e. the parent tree)

sub printParentArrayofHashes {
	my $obj = shift;
	my @grapharrayofhashes;
	foreach my $child ( @{$obj->{'children'}} ) {
		if ( $child->{'name'} eq "" ) {
			next;
		}
		push ( @grapharrayofhashes, $child );
	}
	return \@grapharrayofhashes;
}




#---- printArrayofHashes -------------------------------------------------------
# input: ( $obj, $id )
# Print the child level trees in the cacti graph hash, passed in as $obj
# return ( $grapharrayofhashes );

sub printArrayofHashes {
	my ( $obj , $id ) = @_;
	my @idarray = split( /\./, $id );
	my @grapharrayofhashes;

	# Number of elements in @idarray
	my $numidarray = scalar( @idarray );
	my $count = 0;
	foreach my $idelement ( @idarray ) {
		$count++;

		if ( exists( $obj->{'children'} ) ) {
			$obj = @{$obj->{'children'}}[$idelement];

			# I just want to push the elements into the array over the last iteration
			# Therefore, if we are on the last iteration of @idarray, then we know that
			# $count and $numidarray should be equal
			
			if ( exists( $obj->{'children'} ) && ( $numidarray == $count ) ) {
				foreach my $child ( @{$obj->{'children'}} ){
					if ( $child->{'name'} eq "" ) {
						next;
					}
					push ( @grapharrayofhashes, $child )
				}
			}
		} 
	}
	return ( \@grapharrayofhashes );
}
