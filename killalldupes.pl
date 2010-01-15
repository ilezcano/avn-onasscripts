#!/usr/bin/perl -w

use Opsware::NAS::Client;
use Getopt::Std;
#use XML::Dumper;
use DateTime;
use DateTime::Format::Flexible;
use strict;

$\="\n";
my $killcounter = 0x0;
my %options;
getopts("u:p:s: ", \%options);

my $onas = Opsware::NAS::Client->new();
my $loginresult = $onas->login(-username=>$options{'u'}, -password=>$options{'p'}, -host =>'ryemsnccapp.na.avonet.net');
my $section = $options{'s'};
$section *= 10;

die $loginresult->error_message() unless $loginresult->ok();

my $devicelist = $onas->list_device(family=>'Cisco PIX');

die $devicelist->error_message() unless $devicelist->ok();

my @hostnames = map {$_->{hostName}} $devicelist->results();
#@hostnames = splice(@hostnames, $section, 10);
my %hostresults = map {$_ => 0} @hostnames;

while (scalar(@hostnames) > 0)
	{
	my $host = pop(@hostnames);
	print "Working on $host";
	my $configlist = $onas->list_config(host=>$host);
	
	die $configlist->error_message() unless $configlist->ok();
	
	my $configsref = $configlist->results();
	
	my @sortedconfigs = sort {
			my $atime = DateTime::Format::Flexible->parse_datetime($a->{createDate});
			my $btime = DateTime::Format::Flexible->parse_datetime($b->{createDate});
			DateTime->compare(($btime), ($atime));
			} @$configsref;
	
	my @deviceDataID = map {$_->{deviceDataID}} @sortedconfigs;
	
	$, = "\n";
	if (scalar(@deviceDataID) gt 1)
		{
		my @buffer = splice (@deviceDataID, 0, 2);
	
			do
			{
			my $diffresult = $onas->diff_config(id1=>$buffer[0], id2=>$buffer[1]);
	
			if ($diffresult->results()->[0] =~ /^No d/)
				{
				print "KILL $buffer[0]";
				my $killresult = $onas->del_device_data(id=>$buffer[0]);
				print $killresult->error_message() unless $killresult->ok();
				$killcounter++  if $killresult->ok();
				$hostresults{$host}++;
				}
			else
				{
				print "Difference between configs $buffer[0] and $buffer[1]. Not deleting.";
				}
	
			shift(@buffer);
			push (@buffer, shift(@deviceDataID));
			}	while (scalar(@deviceDataID) gt 0)
		}
	}

foreach my $dip (keys %hostresults)
	{
	print "For host $dip, killed " . $hostresults{$dip};
	}

print "Killed $killcounter total configs.";

$onas->logout();

