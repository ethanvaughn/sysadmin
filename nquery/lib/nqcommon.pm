package lib::nqcommon;

# Functions common to all file types.



use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;


#----- openFile --------------------------------------------------------------
# Parameters: ( filepath )
# Returns: file handle to the specified file.
sub openFile {
	my $filepath = shift;

	open( my $fh, $filepath )
		or die "Unable to open file [$filepath]: $!\n";

	return $fh;
}


1;
