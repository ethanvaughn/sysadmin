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
my $password        = $q->cookie( 'tomaxportalpassword' );
my $nagios_username = $q->cookie( 'tomaxportalcustomer' );
my $upperusername = "\U$nagios_username";
my $id = $q->param( 'id' );
my $showimages = $q->param( 'showimages' );
my %graphwest;
my %graphsouth;
my $westgrapharrayofhashes;
my $southgrapharrayofhashes;


# Authenticate or die.
if (!lib::auth::isValidUser( $portal_username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


# West datacenter or South datacenter
my $dclocation = $q->param( 'dclocation' );

# Decide which datacenter to go to.  True for WDC, 0 for SDC 
# This is different from $dclocation this variable will be used in 
# HTML::Template <tmpl_if name=datacenter> block.  HTML::Template must have the 
# value as either true or false
my $datacenter = 1; 

#DEBUG: Print params to error log: 
#my $vars = $q->Vars;
#print STDERR "PARAMS (DEBUG)\n";
#foreach my $key (keys( %$vars )) {
#   print STDERR "param: $key=$vars->{$key}\n";
#};

init();


#---- init----------------------------------------------------------------------
# Call the functions that read the west and south cacti graph hashes.  If the 
# datacenter location has been set, read the corresponding cacti graph hash

sub init {
	# See comment in buildtree (05/13/08) ... graphtreewest is no
	# longer maintained. This whole conditional is deprecated.
	# The "southtree" is actually the central cacti tree which 
	# included everything.
#print STDERR "Enter init: dclocation = $dclocation\n";
#	if ( defined( $dclocation ) ) {
#		if ( $dclocation eq "west" ) {
#			readWestTree();
#			sendOutput();
#		} elsif ( $dclocation eq "south" ) {
#			readSouthTree();
#			sendOutput();
#		}
#	} else {
#print STDERR "else ... \n";
#		readWestTree();
#		readSouthTree();
#		sendOutput();
#	}
	readSouthTree();
	sendOutput();
}



#---- readWestTree()------------------------------------------------------------
# Read the west cacti hash file
# Deprecated
sub readWestTree {
#print STDERR "readWestTree ... \n";
	my $westobj;
	my $westfile = "/u01/app/portal/lib/graphtreewest";
	tie( %graphwest, "MLDBM", $westfile, O_RDONLY, 0666, ) || die "Cannot open $westfile: $!\n";

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
# This is no longer "read south" since it goes to the .35 cacti server, not the various nagios box.
sub readSouthTree {
#print STDERR "readSouthTree ... \n";
	my $southobj;
	my $southfile = "/u01/app/portal/lib/graphtreesouth";
	tie( %graphsouth, "MLDBM", $southfile, O_RDONLY, 0666, ) || die "Cannot open $southfile\n";

	if ( exists ( $graphsouth{$upperusername} ) ) {
#print STDERR "readSouthTree 1... \n";
		$southobj = $graphsouth{$upperusername};
		$datacenter = 0;
	} else {
#print STDERR "readSouthTree 2... \n";
		$southobj = undef;
	}
	untie( %graphsouth );

	if ( ( $id eq "" ) && ( defined( $southobj ) ) ) {
#print STDERR "readSouthTree 3... \n";
		$southgrapharrayofhashes = printParentArrayofHashes( $southobj );
	} elsif ( ( $id ne "" ) && ( defined( $southobj ) ) ) {
#print STDERR "readSouthTree 4... \n";
		$southgrapharrayofhashes = printArrayofHashes( $southobj, $id );
	} else {
#print STDERR "readSouthTree 5... \n";
		$southgrapharrayofhashes = undef;
	}
}



# ---- sendOutput---------------------------------------------------------------
# Send the data to HTML::Template
sub sendOutput {
#print STDERR "sendOutput ... showimages = $showimages\n";
	if ( $showimages ) {
#print STDERR "sendOutput 1 ... \n";
		lib::createHTML::newTemplate( 'liveshowgraphs', 'Performance Reports', [ $q, $showimages, $dclocation, $datacenter, $portal_username ] );
	}
	if ( ( defined ( $westgrapharrayofhashes ) ) && ( defined ( $southgrapharrayofhashes ) ) ) {
#print STDERR "sendOutput 2 ... \n";
		# Go print the page that has a link to the west and south datacenters
		lib::createHTML::newTemplate( 'datacenter', 'Datacenter Location', [ $q, $portal_username ] );
	} elsif ( defined ( $westgrapharrayofhashes ) ) {
#print STDERR "sendOutput 3 ... \n";
		lib::createHTML::newTemplate( 'livegraphs', 'Performance Reports', [ $q, $westgrapharrayofhashes, $dclocation, $portal_username ] );
	} elsif ( defined ( $southgrapharrayofhashes ) ) {
#print STDERR "sendOutput 4 ... \n";
		lib::createHTML::newTemplate( 'livegraphs', 'Performance Reports', [ $q, $southgrapharrayofhashes, $dclocation, $portal_username ] );
	} 
#print STDERR "sendOutput 5 ... \n";
}




#---- printParentArrayofHashes -------------------------------------------------
# input: ( $obj )
# return ( $grapharrayofhashes );
# Print the top level tree in the hash (i.e. the parent tree)
sub printParentArrayofHashes {
#print STDERR "printParentArrayofHashes ... \n";
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
#print STDERR "printArrayofHashes ... \n";
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
