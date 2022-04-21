package dao::oncall_mysqlconnect;

use strict;
use DBI;

my $dbname = 'oncall';
my $username = 'oncallapi';
my $password = 'oncallapi';
my $host = '10.24.74.35';

##########################################
## Constructor
##########################################

sub new {
	my $class = shift;
	my $self = {};
	# Variables to indicate our status
	$self->{connected} = 0;
	$self->{dberr} = undef;
	# And the connection variables
	$self->{_DBNAME} = $dbname;
	$self->{_USERNAME} = $username;
	$self->{_PASSWORD} = $password;
	$self->{_HOST} = $host;
	bless($self,$class);
	return $self;
}

##########################################
## connect(): establishes DB connection
##########################################

sub connect {
	my $self = shift;
	my $dbh;
	my $result = 0;
	if ($dbh = DBI->connect("DBI:mysql:database=$self->{_DBNAME};host=$self->{_HOST}",$self->{_USERNAME},$self->{_PASSWORD})) {
		$self->{connected} = 1;
		$self->{_DBH} = $dbh;
		$result = 1;
	} else {
		$self->{dberr} = $DBI::errstr;
	}
	return $result;
}

#######################################################################
## _runSelectQuery($sql): private method used to run each select query
#######################################################################

sub _runSelectQuery {
	my $self = shift;
	if (@_) {
		# Clear errors before getting started
		$self->{errstr} = undef;
		# And check if we are connected
		if (!$self->{connected}) {
			# Try to connect or just return.  connect() will set errstr
			# and the caller can take it from there
			$self->connect() || return;
		}
		my $sql = shift || die '_runSelectQuery(sql): argument missing';
		my $sth = $self->{_DBH}->prepare($sql);
		$sth->execute();
		my $errstr = $sth->errstr();
		if (!$errstr) {
			# No errors
			my @rs;
			while(my $h = $sth->fetchrow_hashref()) {
				push(@rs,$h);
			}
			return \@rs;
		} else {
			# Errors!
			$self->{dberr} = $errstr;
		}
	} else {
		die '_runquery: requires a query as an argument';
	}
}

######################################################################
# public methods for running various queries
###################################################################### 

sub getGroupMemberPhone {
	my $self = shift;
	my $sql = <<SQL;
	select
	  groups.name AS group_name,
	  contacts.contact_name,
	  phones.phone
	from groups
	inner join memberships on groups.id = memberships.group_id
	inner join contacts on memberships.contact_id = contacts.id
	inner join phones on contacts.id = phones.cid
	order by group_name asc
SQL
	return $self->_runSelectQuery($sql);
}

sub getGroupMemberEmailAndPager {
	my $self = shift;
	my $sql = <<SQL;
	select
	  lcase(groups.name) AS group_name,
	  contacts.contact_name,
	  contacts.email,
	  contacts.pager
	from groups
	inner join memberships on groups.id = memberships.group_id
	inner join contacts on memberships.contact_id = contacts.id
	order by group_name asc
SQL
	return $self->_runSelectQuery($sql);
}

1;
