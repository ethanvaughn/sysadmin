package lib::execProc;

use strict;
use FindBin qw( $Bin );
use lib "$Bin/..";
use DBI;

my $dbh;

sub execProc {
  # $args is an array ref of arguements to pass (used to build the SQL statement)
  # $setcount indicates whether or not we should count the results and include those in the hash
  my ($proc,$args) = @_;
  connectDB() if !$dbh;
  my $query = "SELECT $proc(";
  foreach my $arg (@$args) {
    # It is important to check if arg is defined -- arg can be zero
    if (defined($arg) && length($arg) > 0) {
    	if($arg eq "true") {     
    		$query.= "\'$arg\',";     
			} elsif($arg eq "false") {
    		$query.= "\'$arg\',";
    	} elsif (($arg =~ /\D/) || ($arg =~ /\d/)) { 
				# If arg contains characters, they need to be quoted         
				$query.= "\'$arg\',";
    	} else { # arg is numbers, does not need quoting
        $query.= "$arg,";
    	}
    } else { # arg is null
      $query.= "NULL,";
    }
  }
  $query =~ s{,$}{}; # Remove ending , appended by foreach loop
  $query.= ');';
  my $rs = $dbh->prepare($query);
  $rs->execute();
	my $error = $DBI::errstr;
  if ($error) {
		print "Something went horribly wrong\n";
  }
  my ($count,@data);
  # Sometimes OLE returns an empty recordset, and then another recordset, such as a select on delete SP.
  # To get the data back that we want, we have to check for multiple recordsets.
  # This code has no effect on single recordsets.  It's also not necessary to close RS when doing this
  while (my $href = $rs->fetchrow_hashref()) # Page through all recordsets and skip empty ones
  {
        push(@data,$href);
        $count++;
  }
  $rs->finish();
  if (@data) {
    return \@data;
  } elsif (defined($count)) {
    return 1;
  } else {
    return;
  }
}

sub connectDB {
  # Setup Database Connection
  $dbh = DBI->connect("dbi:Pg:dbname=portal; port=5432", "postgres", 'p0rt@l');
  if ($DBI::errstr) {
        print $DBI::errstr; # Unable to connect successfully.  Better exit....
  }
}
sub disconnectDB {
  $dbh->disconnect() if $dbh;
}

1;
