use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

sub get_retry {

    my $pfamurl = $_[0];
    my $retries = $_[1];
    my $data = "";
    my $response;

    # Create object
    my $ua = LWP::UserAgent->new();

    for ( 1 .. $retries ) {

        eval { 
           $response = $ua->get($pfamurl);
           $data = from_json($response->decoded_content);
        };
        last unless $@;
        warn "Failed try $_, retrying.  Error: $@\n";
        sleep(2);
    }
    if ($@) { die "failed after ".$retries." tries: $@\n" }

    return $data;
}

sub add_pfam_entry {
  
   # Read arguments
   my $protID = $_[0];
   my $protAC = $_[1];
   my $dbh = $_[2];
   my $debug = $_[3]; 
   
   # Save URLs for Pfam
   my $pfamURL = "https://www.ebi.ac.uk/interpro/api/entry/pfam/protein/uniprot/$protAC/?format=json";
   my $seqURL = "https://www.ebi.ac.uk/interpro/api/protein/uniprot/$protAC/entry/pfam?format=json";

   # Query URLs
   # print "ProtID URL: ".$pfamURL."\n";
   my $data = get_retry($pfamURL, 3);
   my $seq = get_retry($seqURL, 3);

   # Try with accession if there is no information in Pfam
   if ($data eq 'No valid UniProt accession or ID')
   {
        $pfamURL = "https://www.ebi.ac.uk/interpro/api/entry/pfam/protein/uniprot/$protID/?format=json";
        $seqURL = "https://www.ebi.ac.uk/interpro/api/protein/uniprot/$protID/entry/pfam?format=json";

        # print "ProtAC URL: ".$pfamURL."\n";
        $data = get_retry($pfamURL, 3);
        $seq = get_retry($seqURL, 3);
   }

   # Return if there is no entry for this protein
   return "" if ($data eq 'No valid UniProt accession or ID');

   # Retrieve information
   my $sequence = $seq->{metadata}->{sequence};
   my $matches = $data->{results};

   if($matches)
   {
	# Include an entry for each pfam accession
	my $acc="";
	my $type="";
	my $start="";
	my $end="";
        my $clan="";
        my $interpro="";
        my $GOterms=";";
        my $ontologies;
	my $statement="";
	my $pfams = ";";
	my $rv;

        foreach my $match (@{$matches})
	{

	    # Retrieve information for each accession
	    $acc = $match->{metadata}->{accession};
	    $type = "A";#$match->{metadata}->{type};
            
            my $proteins = $match->{proteins};	
         
            # Print Pfam accession
	    print "   PFAM $acc\n";

   	    # Check if this Pfam is already included in database for this protein
   	    $statement = "SELECT EXISTS (SELECT pfam_id, prot_id FROM PFAM_FEATS WHERE pfam_id=\"$acc\" AND prot_id=\"$protID\");";
   	    my @response = $dbh->selectrow_array($statement);
	    next if($response[0]);

	    # Include Pfam in list of domains
	    $pfams = $pfams.$acc.";";
   
	    # Retrieve Pfam information for this domain
	    $pfamURL = "https://www.ebi.ac.uk/interpro/api/entry/pfam/$acc/?format=json";
            # print "PfamACC: ".$pfamURL."\n";
            my $pfdata = get_retry($pfamURL, 3);

	    # 1) Clan identifier if exists
	    $clan = $pfdata->{metadata}->{set_info}->{accession} if $pfdata->{metadata}->{set_info};
            $interpro = $pfdata->{metadata}->{integrated};             

            # 2) GO Terms (Retrieve InterPro information)
            my $iprdata = "";
            if ($interpro){
               $pfamURL = "https://www.ebi.ac.uk/interpro/api/entry/interpro/$interpro?format=json";
               # print "InterPro: ".$pfamURL."\n";
               $iprdata = get_retry($pfamURL, 3);
       	       $ontologies = $iprdata->{metadata}->{go_terms};
            } 
	    foreach my $ontology (@{$ontologies})
	    {
	    	my $term = $ontology->{identifier};
                my $onto = $ontology->{category}->{code};
	    	$term = substr $term,3;
	    	$GOterms = $GOterms."$onto:$term;";
	    }

            # Retrieve each PFAM region
            foreach my $prot (@{$proteins})
            {
               if(uc($prot->{accession}) eq uc($protAC))
               {
                   my $fragments = $prot->{entry_protein_locations};
                   foreach my $frag (@{$fragments})
                   {
                       $start = $frag->{fragments}[0]->{start};
                       $end = $frag->{fragments}[0]->{end}; 
                      
            	       # Save information in Pfam table
		       $statement = "INSERT INTO PFAM_FEATS (prot_id, pfam_id, pfam_seq, pfam_type, start_aa, end_aa, pfam_clan, gos) VALUES (\'".$protID."\', \'".$acc."\', \'".$sequence."\', \'".$type."\', \'".$start."\', \'".$end."\', \'".$clan."\', \'".$GOterms."\');";
		       $rv  = $dbh->do($statement);

                   }
                }
            }		
        }

        return $pfams;
   }
   elsif($sequence)
   {
	print "WARNING - There is no Pfam information associated to the $protID protein \n";
	return "";
   }
   else
   {
	die "Pfam server cannot be connected. Please, try again in a few minutes\n";
   }

}
1;
