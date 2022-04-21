package ArgParse;

###################################################################################################################
#
# Purpose:	Wrapper for Getopt::Std that makes each argument required.
#		Used for most centralized monitoring scripts to eliminate
#		redundant code, since the vast majority of perl scripts
#		all take the same command-line arguments that are all
#		required.  If all of the arguments are not provided,
#		invokes usage($usagestr) and exits
#
# $Id: ArgParse.pm,v 1.2 2008/03/25 02:56:35 jkruse Exp $
# $Date: 2008/03/25 02:56:35 $
#
###################################################################################################################

use strict;
use Getopt::Std;

my $default_timeout = 15;

sub getArgs {
	my ($optstr,$count,$args,$usagestr) = @_;
	if (!$optstr || !$count || ref($args) ne 'HASH' || ref($usagestr) ne 'SCALAR') {
		die 'getArgs($optstr,$count,$args): $optstr(string),$count(int),$args(hash ref),$usagestr(scalar ref)';
	}
	getopts($optstr,$args);
	my $validated_args = 0;
	# getopts will populate $args (hash ref) with key/value pairs of the option (-X, -Y, -Z..)
	# and the values being the parameter to each command-line option.  If each value is defined,
	# it was a valid -X <param> argument.  If a value is undef, it means either the option (-X)
	# or the value (-X <param>) was missing.  This is just a cheap way to make sure that all
	# of the command-line arguments were used and given arguments.
	foreach my $val (values(%$args)) {
		if (defined($val)) {
			$validated_args++;
		}
	}
	# Timeout is optional.  If it's not defined, the default of $default_timeout
	# will be used, and $validated_args will be incremented appropriately.  Otherwise,
	# the timeout specified on the command-line will be retained.  By testing 
	# to see if $args{t} does not exist (hash key t not present) or if the value
	# of hash key t is not set ($args{t}) this allows -t to be empty, absent, or defined
	if (!exists($args->{t}) || !defined($args->{t})) {
		$args->{t} = $default_timeout;
		$validated_args++;
	}
	if ($validated_args != $count) {
		usage($usagestr);
	} else {
		return;
	}
}

sub usage {
	my $str_ref = shift;
	printf('%s: %s%s',$0,$$str_ref,"\n"); # Print usage to stdout
	exit 3;	# Exit code for unknown
}

1;
