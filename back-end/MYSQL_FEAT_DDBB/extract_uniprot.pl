use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;	

my $list = $ARGV[0];

my $base = 'http://www.uniprot.org';
my $tool = 'batch';

my $contact = ''; # Please set your email address here to help us debug in case of problems.
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");

push @{$agent->requests_redirectable}, 'POST';


my $response = $agent->post("$base/$tool/",
                            [ 'file' => [$list],
                              'format' => 'txt',
                              'from' => 'ACC+ID',
                              'to' => 'ACC',
                            ],
                            'Content_Type' => 'form-data');


while (my $wait = $response->header('Retry-After')) {
  print STDERR "Waiting ($wait)...\n";
  sleep $wait;
  $response = $agent->get($response->base);
}

$response->is_success ?
  print $response->content :
  die 'Failed, got ' . $response->status_line .
    ' for ' . $response->request->uri . "\n";
