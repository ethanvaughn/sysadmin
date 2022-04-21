package lib::URLQuery;

use strict;
use LWP;

my $proxy = '10.24.74.13';
my @urls = qw(nquery/wdc nquery/sdc);

my $ua = LWP::UserAgent->new();
$ua->timeout(30);

sub fetchURL {
	my $url = shift;
	my $data;
	my $status;
	foreach my $proxy_url (@urls) {
		# $proxy_url is the base URL on the reverse proxy server
		# $url is the real URL to be queried through the proxy
		my $complete_url = sprintf('http://%s/%s/%s',$proxy,$proxy_url,$url);
		my $response = $ua->get($complete_url);
		if ($response->is_success) {
			$status++;
			$data.= ${$response->content_ref};
		} else {
			print 'Content-type: text/plain',"\n\n";
			print $response->status_line;
			print "\r\n\r\n";
			print $complete_url;
			print "DEBUG 10024\n";
		}
	}
	if ($status == scalar(@urls)) {
		return \$data;
	} else {
		error();
	}
}

sub error {
	print 'Refresh: 60',"\n";
	print 'Content-type: text/plain',"\n\n";
	print 'Retrieving data from servers...please be patient as data is loaded.',"\r\n";
	print 'The page will automatically refresh in 1 minute.';
	exit -1;
}

1;
