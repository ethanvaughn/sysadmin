#!/usr/bin/perl

use strict;

# Script to make the necessary modifications to the /etc/sudoers file.
# Preserves any local settings above the "##TOMAXBEGIN" and below the
# "##TOMAXEND" tags.

# Globals
my $sudoers = "/usr/local/etc/sudoers";
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


# Our monochromatic friend:
tmxaudit       ALL=(ALL) NOPASSWD: ALL


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

Cmnd_Alias	SU_DEV = \\
	/bin/su - jboss

Cmnd_Alias	SU_DB = \\
	/bin/su - oraclelab,\\
	/bin/su - oaslab,\\
	/bin/su - rflab,\\
	/bin/su - tomaxlab,\\ 
	/bin/su - oasj2ee

Cmnd_Alias SU_SUP = \\
	/bin/su - tomax

# Sundry commands 
Cmnd_Alias	CMD_DB = \\
	/bin/chown,\\
	/usr/bin/du



# Centrally controlled defaults. Put local-specific directives after TOMAXEND. 
%dba		ALL =(ALL) NOPASSWD: SU_COMMON, SU_DB, CMD_DB
%sysdev		ALL =(ALL) NOPASSWD: SU_COMMON, SU_DEV
%syssup		ALL =(ALL) NOPASSWD: SU_SUP


# WARNING: This rule will give full root access to the members of the 
# "dba" group. If you enable this for a maintenance window, 
# YOU ARE RESPONSIBLE TO DISABLE IT afterward. (If you fail to secure it,
# you and your children\'s children will be ridiculed for generations.)
#%dba        ALL=(ALL) NOPASSWD: ALL

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
