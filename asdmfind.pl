#!/usr/bin/perl -w

use strict;

local $, = "\n";
local $\ = "\n";
my @slurp = do {<>};
my @asdmlines = grep (/^asdm location/, @slurp);
chomp (@asdmlines);
my %asdms = map { my ($octets) = /location (\S+ \S+)/; $octets => $_} @asdmlines;
my @targetlinerefs = map {
			my $dippy = $_;
			$asdms{$_} if scalar(grep (/^(?!asdm|name).*$dippy/, @slurp)) eq 0;
			} keys (%asdms);

foreach my $line (@targetlinerefs)
	{
	next if length($line) == 0;
	print "no $line";
	}
