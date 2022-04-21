#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::item;
use lib::company;
use lib::template;
#use lib::property;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $template;
my $itemname;
my $comment;
my $serialno;
my $ownercode;
my $users;


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 't:Uh:c:s:o:u:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -U is in arg list:
	usage_exit() if ($opt{U});

	# Exit if any of the required args are missing:
	#if (!$opt{c} or !$opt{d} or !$opt{g}) {
	if (!$opt{h}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Passed all argument checks. Load the variables:
	$template  = $opt{t} if $opt{t};
	$itemname  = $opt{h} if $opt{h};
	$comment   = $opt{c} if $opt{c};
	$serialno  = $opt{s} if $opt{s};
	$ownercode = $opt{o} if $opt{o};
	$users     = $opt{u} if $opt{u};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Add item to inventory.

usage: 
    $0 -t template_name -h itemname [-c "comment"] [-s serialno] [-o ownercode] [-u "user,user,user"]

    $0 -  --> Show this usage.

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

# Get the template id:
my $tmpl = lib::template::getTemplateByName( $dbh, $template ) ||
	die "Unable to get template id: $!\n";

# Populate item rec from command-line args: 
my $rec;
$rec->{tmplid} = $tmpl->{id};
$rec->{itemname} = $itemname;
$rec->{serialno} = '';
$rec->{serialno} = $serialno if ($serialno);
$rec->{comment} = '';
$rec->{comment} = $comment if ($comment);
$rec->{admin_notes} = '';
$rec->{notes} = '';

# Add the item
if (!lib::item::addItem( $dbh, $rec )) {
	my $errstr = $dbh->errstr;
	print STDERR "Unabe to add item: $errstr\n";
	$dbh->rollback;
	exit 1;
}

print 'Added item: [' . $itemname . "]\n";

# Retrieve the id for the new item ... 
my $item_id = lib::item::getItemId( $dbh, $itemname );
if (!$item_id) {
	my $errstr = $dbh->errstr;
	print STDERR "Unabe to get item id: $errstr\n";
	$dbh->rollback;
	exit 1;
}

# Add owner 
if ($ownercode) {
	my $owner = lib::company::getCompanyByCode( $dbh, $ownercode );
	if (!$owner) {
		my $errstr = $dbh->errstr;
		print STDERR "Unabe to get company id: $errstr\n";
		$dbh->rollback;
		exit 1;
	}
	print "    Set owner: $ownercode [$owner->{id}]\n";
	if (!lib::item::setOwner( $dbh, $item_id, $owner->{id} )) {
		my $errstr = $dbh->errstr;
		print STDERR "Unabe to set owner: $errstr\n";
		$dbh->rollback;
		exit 1;
	}
}


# Add user
if ($users) {
	my @userlist;
	my @uids;
	@userlist = split( /,/, $users );
	foreach my $usercode (@userlist) {
		my $urec = lib::company::getCompanyByCode( $dbh, $usercode );
		print "    Set user: $usercode [$urec->{id}]\n";
		push( @uids, $urec->{id} );
	}
	lib::item::setUsers( $dbh, $item_id, \@uids );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: Database error setUsers: $errstr\n";
}


$dbh->commit;

dao::saconnect::disconnect( $dbh );



exit (0);
