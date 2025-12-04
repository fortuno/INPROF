use strict; 
use warnings; 
use LWP::UserAgent; 
use HTTP::Request::Common qw{ POST }; 
use JSON; 

sub uniprot_mapping {

      my $base = 'https://rest.uniprot.org';
      my $tool = 'idmapping';
      my @mapIds;

      my $query = $_[0];

      my $params = {
          from => 'UniProtKB_AC-ID',
          to => 'UniProtKB',
          ids => $query
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

      #if (exists $mapping->{"results"}){
      #     @mapIds = @{$mapping->{"results"}};
      #}

      #print("$base/$tool/uniprotkb/results/$jobid?size=500");
      $jobres  = $ua->get("$base/$tool/uniprotkb/results/$jobid?size=500");
      $mapping = from_json($jobres->decoded_content);
      @mapIds = @{$mapping->{"results"}};

      return(@mapIds);

}
1;
