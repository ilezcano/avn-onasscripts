#!/usr/bin/perl -w

use Opsware::NAS::Client;
use Getopt::Std;
#use XML::Dumper;
use strict;

my %options;
getopts("u:p: ", \%options);
my $onas = Opsware::NAS::Client->new();
my $result = $onas->login(-username=>$options{'u'}, -password=>$options{'p'}, -host =>'ryemsnccapp.na.avonet.net');

die $result->error_message() unless $result->ok();
# Get a Server List

$result = $onas->list_device(type=>'L3Switch');

warn $result->error_message() unless $result->ok();

my $serverlistref = $result->results();

foreach my $server (@$serverlistref)
	{
	local $\ = "\n";
	my $devicename = $server->{hostName};
	next unless ($devicename =~ /\(r\)/i);
	print $devicename;
	my $newdevicename = $devicename;
	$newdevicename =~ s/\([rR]\)/r/g;
	print $newdevicename;
	my @array = "hostname $newdevicename";
	#$result = $onas->run_script( host=>$devicename, mode=>'Cisco IOS configuration', comment=>'CRQ000000013860', script=>"@array");
	#warn $result->error_message() unless $result->ok();
	print @array;
	}

$onas->logout();
