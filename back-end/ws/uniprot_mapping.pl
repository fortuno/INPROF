use strict;
use warnings;
use LWP::UserAgent;

sub uniprot_mapping {

	my $base = 'http://www.uniprot.org';
	my $tool = 'mapping';
	my $mapping = '';

	my $query = $_[0];

	my $params = {
  	    from => 'ACC+ID',
  	    to => 'ID',
  	    format => 'tab',
  	    query => $query 
	};

	my $contact = ''; # Please set your email address here to help us debug in case of problems.
	my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");
	push @{$agent->requests_redirectable}, 'POST';

	my $response = $agent->post("$base/$tool/", $params);

	while (my $wait = $response->header('Retry-After')) {
  		print STDERR "Waiting ($wait)...\n";
  		sleep $wait;
  		$response = $agent->get($response->base);
	}

	$response->is_success ?
  	$mapping =  $response->content :
  	die 'Failed, got ' . $response->status_line .
    		' for ' . $response->request->uri . "\n";

       return ($mapping);
}
1;