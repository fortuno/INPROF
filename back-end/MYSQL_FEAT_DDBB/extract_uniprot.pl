use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;	
use HTTP::Request::Common qw{ POST }; 
use JSON;

my $protfile = $ARGV[0];
my $list = do {
    local $/ = undef;
    open my $fh, "<", $protfile
        or die "could not open $protfile: $!";
    <$fh>;
};

my $fastafile = $protfile =~ s/txt/fasta/r;

my $base = 'http://rest.uniprot.org';
my $tool = 'idmapping';

my $params = {
    from => 'UniProtKB_AC-ID',
    to => 'UniProtKB',
    ids => $list
};

my $ua = LWP::UserAgent->new();
my $request = POST("$base/$tool/run", $params);
my $response = $ua->request($request);

$response->is_success ?
my $content = $response->content :
die 'Failed, got ' . $response->status_line .
    ' for ' . $response->request->uri . "\n";

my $jobid = from_json($content)->{"jobId"};
my $jobres;
my $mapping;
my $sequences;
my $status = "RUNNING";

while ($status eq "RUNNING") {
     $jobres  = $ua->get("$base/$tool/status/$jobid");
     $mapping = from_json($jobres->decoded_content);
           
     if (exists $mapping->{"jobStatus"}){
          $status = $mapping->{"jobStatus"};
          print STDERR "Waiting (2)...\n";
          sleep 2;
     }
     else{
          $status = "FINISHED";
     }
}

if ($status ne "FINISHED"){
      die 'Failed, got ' . $response->status_line .
          ' for ' . $response->request->uri . "\n";
}

$jobres  = $ua->get("$base/$tool/uniprotkb/results/$jobid?size=500&format=txt");
$mapping = $jobres->decoded_content;

# Get FASTA and save in file
$jobres  = $ua->get("$base/$tool/uniprotkb/results/$jobid?size=500&format=fasta");
$sequences = $jobres->decoded_content;
open(my $fh, '>', $fastafile);
print $fh $sequences;
close $fh;

print($mapping);
