#!/usr/bin/perl -w

use Opsware::NAS::Client;
use Getopt::Std;
use XML::Dumper;
use DateTime;
use DateTime::Format::Flexible;
use strict;

my %options;
getopts("u:p:h: ", \%options);

my $onas = Opsware::NAS::Client->new();
my $loginresult = $onas->login(-username=>$options{'u'}, -password=>$options{'p'}, -host =>'ryemsnccapp.na.avonet.net');

die $loginresult->error_message() unless $loginresult->ok();

my $configlist = $onas->list_config(host=>$options{'h'});

die $configlist->error_message() unless $configlist->ok();

my $configsref = $configlist->results();

my $killcounter = 0x0;

my @sortedconfigs = sort {
		my $atime = DateTime::Format::Flexible->parse_datetime($a->{createDate});
		my $btime = DateTime::Format::Flexible->parse_datetime($b->{createDate});
		DateTime->compare(($btime), ($atime));
		} @$configsref;

#foreach my $configmeta (@sortedconfigs)
	#{
	#local $\ = "\n";
	#print $configmeta->{deviceDataID} , $configmeta->{createDate};
	#}

my @deviceDataID = map {$_->{deviceDataID}} @sortedconfigs;

$, = "\n";
if (scalar(@deviceDataID) gt 1)
	{
	local $\="\n";
	my @buffer = splice (@deviceDataID, 0, 2);
	#my @buffer = (pop @deviceDataID, pop @deviceDataID);

		do
		{
		my $diffresult = $onas->diff_config(id1=>$buffer[0], id2=>$buffer[1]);

		if ($diffresult->results()->[0] =~ /^No d/)
			{
			print "KILL $buffer[0]";
			my $killresult = $onas->del_device_data(id=>$buffer[0]);
			print $killresult->error_message() unless $killresult->ok();
			$killcounter++ if $killresult->ok();
			}
		else
			{
			print "Difference between configs $buffer[0] and $buffer[1]. Not deleting.";
			}

		shift(@buffer);
		push (@buffer, shift(@deviceDataID));
		}	while (scalar(@deviceDataID) gt 0)
	}

print "Killed $killcounter configs.";

$onas->logout();

