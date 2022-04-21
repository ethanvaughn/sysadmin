#!/usr/bin/perl

# Purpose: Runs a user-supplied command, sends output + exit code to $server (passive check)

use strict;
use GetOpt::Long;
use Net::SMTP;

# Globals
my ($cmd,$service,$exit);
# SMTP Server to send results to
my $server = '10.24.74'9;

sub runCommand {
}

sub sendResults {
}

