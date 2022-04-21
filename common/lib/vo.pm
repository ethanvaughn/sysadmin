package lib::vo;


use FindBin qw( $Bin );
use lib "$Bin/..";


#----- scrub ---------------------------------------------------------
# Arguments: hashref from the cgi->Vars method.
# Scrub input fields of any invalid characters. 
# Returns: scrubbed hashref to replace vars in the caller.
sub scrub {
	my $vars = shift;
	
	foreach my $key (keys( %$vars )) {
		if ($vars->{$key} !~ /navback/) {
			$vars->{$key} =~ tr/\$\^+"';,{}<>\\\?`~\*\|//d;
		}
	}

	return $vars;
}



#----- lcase ----------------------------------------------------------------
sub lcase {
	my $field = shift;
	$field =~ tr [A-Z] [a-z];
	return $field;
}



#----- validate_itemname -----------------------------------------------------
sub validate_itemname {
	my $itemname = shift;
	if ($itemname =~ /[~`!@#%^&*()+=;,\/?|\s"'<>{}\$\[\]\\].*/) {
		return 0;
	}
	
	return 1;
}


1;
