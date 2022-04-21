package lib::database;

use FindBin qw( $Bin );
use lib "$Bin/..";
use DBI;

sub execSelectQuery {
	my ( $query, $column ) = @_;
	connectMysqlDB("10.24.74.9") if !$mysqldbh;
  my $sth = $mysqldbh->prepare( "$query" );
	$sth->execute();
	my $href = $sth->fetchall_hashref("$column");
	$sth->finish();
	return $href;
}

sub execDeleteQuery {
	my $query = shift;
	connectPgDB("10.24.74.45") if !$pgdbh;
  my $sth = $pgdbh->prepare( "$query" );
	$sth->execute();
	$sth->finish();
}

sub connectMysqlDB {
	my $hostname = shift;
	$database = "cacti";
	$port = "3306";
	$user = "portal";
	$pass = 'p0rt@l';
	$dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
	$mysqldbh = DBI->connect($dsn, $user, $pass);
	if ( $DBI::errstr ) {
		print $DBI::errstr;
	}
}

sub connectPgDB {
	my $hostname = shift;
	$database = 'portal';
	$port = '5432';
	$user = 'portal';
	$pass = 'p0rt@l';
	$dsn = "DBI:Pg:database=$database;host=$hostname;port=$port";
	$pgdbh = DBI->connect($dsn, $user, $pass);
	if ( $DBI::errstr ) {
		print $DBI::errstr;
	}
}

1;
