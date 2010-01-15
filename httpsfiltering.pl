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

$result = $onas->list_device(family=>'Cisco PIX');

warn $result->error_message() unless $result->ok();

my $serverlistref = $result->results();

foreach my $server (@$serverlistref)
	{
	local $\ = "\n";
	my $devicename = $server->{hostName};
	$result = $onas->show_snapshot( host=>$devicename );
	my @config = $result->results();
	my @array = $config[0] =~ m#^filter .*#mg;
	next if (grep(/^filter https/, @array));
	next unless (@array > 0);
	print $devicename;
	
	$result = $onas->run_script( host=>$devicename, mode=>'Cisco PIX configuration', comment=>'CRQ000000005711', script=>"filter https 443 0.0.0.0 0.0.0.0 0.0.0.0 0.0.0.0 allow");
	warn $result->error_message() unless $result->ok();
	}

$onas->logout();
