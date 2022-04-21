package www::cgi::helpers;


use FindBin qw( $Bin );
use lib "$Bin/../..";

use CGI;
use HTML::Template;

use lib::time;


#----- Exported -----------------------------------------------
our $LOGON_MSG = 'You are logged on as ';


#----- Global ----------------------------------------------------------------
my $cgi = new CGI;

#----- chkDB -----------------------------------------------------------------
# Parameters ($dbh)
# Check for DB errors. If errors exist, short circuit to the error dialog.
# WARNING: This fuction may exit without returning to caller. 
sub chkDB {
	$dbh = shift;

	my $ts = lib::time::now();

	# Generic error to display:
	$msg = <<EOL;
An Application Error Occurred.</br>
</br>
Please contact SysAdmin with the following information:</br>
</br>
Log Time = [$ts]</br>
</br>
EOL

	if (!$dbh) {
		# Log it:
		print STDERR "SA-Inventory: Unable to establish DB connection.\n";

		# Load and display the error message:
		$htmlview = HTML::Template->new( filename => "../tmpl/error_dlg.tmpl" );
		$htmlview->param( msg => $msg );
		print $cgi->header;
		print $htmlview->output;
		exit (1);
	}

	# In this case dbh is valid. Check for an error condition.
	my $errstr = $dbh->errstr;
	if ($errstr) {

		dao::saconnect::disconnect( $dbh );
		# Log it:
		print STDERR $errstr;
		
		# Load and display the error message:
		$htmlview = HTML::Template->new( filename => "../tmpl/error_dlg.tmpl" );
		$htmlview->param( msg => $msg );
		print $cgi->header;
		print $htmlview->output;
		exit (1);
	}
}



#----- exitonerr -------------------------------------------------------------
# Parameters ($errnav, $errmsg, $errtmpl)
# Log $errmsg to STDERR then load and display error dialog specified in $errtmpl.
# Note: This function will exit without returning to caller.
sub exitonerr {
	$errnav  = shift;
	$errmsg  = shift;
	$errtmpl = shift;

	$errtmpl = "../tmpl/error_dlg.tmpl" if (!$errtmpl);
	
	print STDERR $errmsg;
	
	$htmlview = HTML::Template->new( filename => $errtmpl );
	$htmlview->param( errnav => $errnav );
	$htmlview->param( msg    => $errmsg );
	print $cgi->header;
	print $htmlview->output;
	exit (1);
}



#----- gen_tabmenu -----------------------------------------------------------
# Parameters (app)
# Returns string of the HTML required to handle the main application menu.
sub gen_tabmenu {
	my $app = shift;
	
	# A little fun: set the logo based on date. I've not obfuscated it at all
	# so just the tiniest bit of research and you'll see what this does.
	my @date = localtime();
	my $logo = "opslogo-stencil.png";
	if ( ($date[3] % 2) == 0 ) {
		$logo = "opslogo-bank.png";
	}
	if ( $date[7] == 256 ) {
		$logo = "opslogo-herc.png";
	}
	if ( $date[7] == 220 ) {
		$logo = "opslogo-japanese.png";
	}
	if ( $date[7] == 113 ) {
		$logo = "opslogo-chinese.png";
	}
	if ( $date[7] == 297 ) {
		$logo = "opslogo-korean.png";
	}

	# Select active tab based on paremeter:
	my $inv = "";
	my $addr = "";
	my $auth = "";
	my $oncall = "";
	my $serv = "";
	if ($app eq "INV") {
		$inv = qq|class="active"|;
	} elsif ($app eq "ADDR") {
		$addr = qq|class="active"|;
	} elsif ($app eq "AUTH") {
		$auth = qq|class="active"|;
	} elsif ($app eq "ONCALL") {
		$oncall = qq|class="active"|;
	} elsif ($app eq "SERV") {
		$serv = qq|class="active"|;
	}

 	return <<EOL;
		<ul id="tabmenu">
			<li><a  href="../inventory/main" $inv>Inventory</a></li>
			<li><a  href="../addr/main" $addr>Addressing</a></li>
			<li><a  href="../auth/main" $auth>Auth</a></li>
			<li><a  href="../oncall/main" $oncall>On-Call</a></li>
			<li><a  href="../serv/main" $serv>Service</a></li>
			<img class="logo" src="../commonhtml/images/$logo">
		</ul>
EOL
}



#----- getFlag ---------------------------------------------------------------
# Return an img tag for a random flag image.
sub getFlag  {
	my  $max = 105;
	
	my $rand = int( rand( $max ) );
	
	return <<EOL;
		<img src="../commonhtml/images/flags/$rand.gif">
EOL
}



1;
