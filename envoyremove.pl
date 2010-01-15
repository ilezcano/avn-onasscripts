#!/usr/bin/perl -w

use Opsware::NAS::Client;
use Getopt::Std;
use XML::Dumper;
use strict;

my %options;
getopts("u:p: ", \%options);
my $onas = Opsware::NAS::Client->new();
my $result = $onas->login(-username=>$options{'u'}, -password=>$options{'p'}, -host =>'ryemsnccapp.na.avonet.net');

die $result->error_message() unless $result->ok();
# Get a Server List

$result = $onas->list_device(family=>'Cisco IOS');

warn $result->error_message() unless $result->ok();

my $serverlistref = $result->results();

# 204.145.3.16
# 204.145.3.19
# CRQ000000004486

foreach my $server (@$serverlistref)
	{
	local $\ = "\n";
	my $devicename = $server->{hostName};
	next if ($devicename =~ /ex01r/i);
	$result = $onas->show_snapshot( host=>$devicename );
	my @config = $result->results();
	my @array = $config[0] =~ m#^ip (?:route 204\.145\.3\.16 255\.255\.255\.240.*|prefix-list.*204\.145\.3\.16/28.*)#mg;
	next unless (@array > 0);
	@array = map {"no $_\n" } @array;
	print $devicename;
	print @array;
	
	$result = $onas->run_script( host=>$devicename, mode=>'Cisco IOS configuration', comment=>'CRQ000000004486', script=>"@array");
	warn $result->error_message() unless $result->ok();
	}

$onas->logout();
