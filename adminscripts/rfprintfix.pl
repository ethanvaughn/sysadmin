#!/usr/bin/perl
#
# Author: John Malouf
# 
# Set $DEBUG=1 if you want to recieve debug email.
#

#----- Globals ----------------------------------------------------------------
$DEBUG=0;
$recipients="sysadmin\@tomax.com";

my $i = 0; # Index for message array
$HOST=`hostname`;
$PTR_CONF="/etc/cups/printers.conf";



#----- main -------------------------------------------------------------------
# Set "ErrorPolicy" to "retry" rather than "stop" for all print queues.
open( GRP, "/bin/grep stop-printer /etc/cups/printers.conf |" );
if (<GRP>) {
	print "Modifying printers.conf\n";
	open(I_PTR, "$PTR_CONF");
	open(O_PTR, ">/tmp/printers.conf");

	while (<I_PTR>) {
		if ($_ =~ /^ErrorPolicy/) {
			print O_PTR "ErrorPolicy retry-job\n";
			next;
		}
		print O_PTR $_;
	}
	system( "/bin/cp /tmp/printers.conf /etc/cups/printers.conf" );
	system( "/sbin/service cups restart" );
}


# Ensure queue is not stopped.
open( DISABLED, "/usr/bin/lpstat -p|/bin/grep -i disable |" );
while (<DISABLED>) {
    ($goo, $printer, $goo) = split(/\s+/, $_);
    print "Enabling $printer\n";
    @message[$i++] = "$HOST: Enabling $printer\n";
    system( "/usr/sbin/cupsenable $printer" );
}
close(DISABLED);


# Ensure queue is accepting jobs.
open(REJECT, "/usr/bin/lpstat -a|/bin/grep -i \"not accepting\" |");
while(<REJECT>) {
    ($printer, $goo, $goo) = split(/\s+/, $_);
#    print("Accepting $printer\n");
    @message[$i++] = "$HOST: Accepting $printer\n";
    system("/usr/sbin/accept $printer");
}
close(REJECT);



# Prep and send email for DEBUG case ...
foreach $mess (@message) {
	$test = "$test . $message[$mess]";
}

if ($test && $DEBUG) {
	system( "echo \"@message\" | /u01/app/utils/mail.pl -s \"rfprinterfix\" $recipients" );
}


exit (0);