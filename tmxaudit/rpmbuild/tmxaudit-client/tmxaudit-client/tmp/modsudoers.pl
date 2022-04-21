#!/usr/bin/perl

use strict;

# Script to make the necessary modifications to the /etc/sudoers file.
# Preserves any local settings above the "##TOMAXBEGIN" and below the
# "##TOMAXEND" tags.

# Globals
my $sudoers = "/etc/sudoers";
my $tmxsudoers = $sudoers.".tmxaudit";

# Backup:
`cp $sudoers ${sudoers}.bak`;


# Open and parse the file:
open( SUDOERS, "<$sudoers" ) or
	die "Unable to open $sudoers: $!\n\n";
open( TMXSUDOERS, ">$tmxsudoers" ) or
	die "Unable to open $tmxsudoers: $!\n\n";


# Read down to "##TOMAXBEGIN
while (<SUDOERS>) {
	if ($_ =~ /##TOMAXBEGIN/) {
		last;
	}
	print TMXSUDOERS $_;
}


# Skip down to TOMAXEND:
while (<SUDOERS>) {
	if ($_ =~ /##TOMAXEND/) {
		last;
	}
}


# Write the centrally-managed part
print TMXSUDOERS <<EOL;
##TOMAXBEGIN
# Configuration for Tomax sudoers.
#


# Members of the "sysadmin" group have full access:
%sysadmin       ALL=(ALL) NOPASSWD: ALL


# List of default local accounts inaccessible from remote login. Add any
# custom local accounts to this list. (Watch your punctuation.)
Cmnd_Alias	SU_COMMON =	\\
	/bin/su - oracle,\\
	/bin/su - oracledev,\\
	/bin/su - oas,\\
	/bin/su - oasdev,\\
	/bin/su - rf,\\
	/bin/su - rfdev,\\
	/bin/su - tomax,\\ 
	/bin/su - tomaxdev,\\ 
	/bin/su - notes,\\
	/bin/su - notes,\\
	/bin/su - notesdev,\\
	/bin/su - jboss

Cmnd_Alias	SU_DB = \\
	/bin/su - oraclelab,\\
	/bin/su - oaslab,\\
	/bin/su - rflab,\\
	/bin/su - tomaxlab,\\ 
	/bin/su - oasj2ee,\\
	/bin/su - ftpdl

Cmnd_Alias SU_SUP = \\
	/bin/su - tomax

# Sundry commands 
Cmnd_Alias	CMD_DB = \\
	/bin/chown,\\
	/usr/bin/du



# Centrally controlled defaults. Put local-specific directives after TOMAXEND. 
%sysdba		ALL =(ALL) NOPASSWD: SU_COMMON, SU_DB, CMD_DB
%sysdev		ALL =(ALL) NOPASSWD: SU_COMMON
%syssup		ALL =(ALL) NOPASSWD: SU_SUP

##TOMAXEND
EOL


# Finish any local overrides or additions:
while (<SUDOERS>) {
	print TMXSUDOERS $_;
}

close( SUDOERS );
close( TMXSUDOERS );

`cp -f $tmxsudoers $sudoers`;
`chmod 440 $sudoers $tmxsudoers ${sudoers}.bak`;

exit 0
