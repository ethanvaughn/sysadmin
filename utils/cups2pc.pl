#!/usr/bin/perl

use strict;


#----- usage_exit ------------------------------------------------------------
sub usage_exit {
	print STDERR << "EOF";

Translate the CUPS printer.conf format to LPRng printcap to STDOUT.

Usage:
    $0 [file] > outfile

EOF
	exit (1);
}



#----- print_error ------------------------------------------------------------
sub print_error {
	my $path = shift;
	my $msg = shift;

	print STDERR "\n";
	print STDERR "Unable to open CUPS printer file: $path\n";
	print STDERR "$msg\n";
	print STDERR "\n";
	
	usage_exit();
}



#----- Main Script -----------------------------------------------------------
my @rec = ();

my $cupsfile = "/etc/cups/printers.conf";
if ($#ARGV eq 0) {
	$cupsfile = $ARGV[0];
}

open( CUPSFILE, "<$cupsfile") or print_error( $cupsfile, $! );

my $i = 0;
while (<CUPSFILE>) {
	my $line = $_;
	chomp $line;

	if ($line =~ /<Printer/ or $line =~ /DefaultPrinter/ or $line =~ /DeviceURI/) {
		 $rec[$i] = $rec[$i] . " " . $line;
	}
	
	if ($line =~ /<\/Printer/) {
		$i++;
	}

}

close( CUPSFILE );

# Insert the ".common" directive before the individual printers:
print qq|
.common:
   :sd=/var/spool/lpd/%P
   :sh:mx=0:mc=0

#   [Translation:
#   .common - the period (.) causes LPRng to treat this as a 'information
#      only entry. 
#   :sd=/var/spool/lpd/%P
#      Spool queue directory for temporary storage of print jobs.  The
#      %P will be expanded with the print queue name.  Each print queue
#      MUST have a different spool queue directory,  and by using %P
#      this is guaranteed.
#   :sh  - suppress banners or header pages
#   :mx=0 - maximum job size in K bytes (0 is unlimited)
#   :mc=0 - maximum number of copies (0 is unlimited)
#   ]

|;

foreach (@rec) {
	(my $name = $_) =~ s/^ <.*Printer (.*)> .*$/$1/;
	(my $ip   = $_) =~ s/^ <.*Printer.*lpd:\/\/(.*)\/.*$/$1/;
	print "$name:tc=.common:lp=zebra\@$ip\n";
}


exit (0);
