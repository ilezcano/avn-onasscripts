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

$result = $onas->list_device(group=>'Envoys');

warn $result->error_message() unless $result->ok();

my $serverlistref = $result->results();

# For each Server, find the ACL Name
foreach my $server (@$serverlistref)
	{
	my $devicename = $server->{hostName};
	print "$server->{hostName}\n";
	$result = $onas->show_snapshot(host => $devicename);
	warn $result->error_message() unless $result->ok();
	my @configtext = $result->results(); # Don't be fooled. This is a single element array. Might as well be a scalar.
	next unless $configtext[0] =~ /object-group network Envoy-II-Webs/;
	my ($aclname) = $configtext[0] =~ /(\S+)(?= in interface inside)/; #Find the ACL Name
	my @acl = $configtext[0] =~ /access-list $aclname[^\n]+\n/g; #Build the ACL array

	# Alter the ACL
	foreach (grep(/access-list $aclname permit tcp any host 204\.145\.3\.19/, @acl))
		{
		s/host \d+\.\d+\.\d+\.\d+ (?=object-group)/object-group Envoy-II-Webs /;
		}

	# Append commands to make the command script
	push (@acl, "access-group $aclname in interface inside\n");
	unshift(@acl, "no access-list $aclname\n");

	# Schedule Task

	$result = $onas->run_script( host=>$devicename, mode=>'Cisco PIX configuration', comment=>'CRQ000000057745 phase ii', script=>"@acl");
	warn $result->error_message() unless $result->ok();
	}


$onas->logout();
