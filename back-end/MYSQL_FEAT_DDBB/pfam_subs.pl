use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use LWP::Simple;

sub add_pfam_entry {
  
   # Read arguments
   my $protID = $_[0];
   my $protAC = $_[1];
   my $dbh = $_[2];
   my $debug = $_[3]; 
   
   # Save URL with the XML in Pfam
   my $xmlURL = "http://pfam.xfam.org/protein/$protID?output=xml";

   # Create object
   my $xml = XML::Simple->new();
   
   # Read XML file
   my $data = $xml->XMLin(get($xmlURL), KeyAttr => { package => 'id' });

   # Try with accession if there is no information in Pfam
   if ($data eq 'No valid UniProt accession or ID')
   {
	$xmlURL = "http://pfam.xfam.org/protein/$protAC?output=xml";
	$data = $xml->XMLin(get($xmlURL), KeyAttr => { package => 'id' });
   }

   # Return if there is no entry for this protein
   return "" if ($data eq 'No valid UniProt accession or ID');
 
   # Retrieve information
   my $sequence = $data->{entry}->{sequence}->{content};
   my $matches = $data->{entry}->{matches}->{match}; 

   if($matches)
   {
	   # Include an entry for each pfam accession
	   my $acc="";
	   my $type="";
	   my $start="";
	   my $end="";
           my $clan="";
           my $GOterms=";";
           my $ontologies;
	   my $statement="";
	   my $pfams = ";";
	   my $rv;
	   
           $matches = [$matches] if ref($matches) eq "HASH";
           foreach my $match (@{$matches})
	   {
		# Retrieve information for each accession
		$acc = $match->{accession};
		$type = $match->{type};	
		$type = substr($type, -1, 1);
		$start = $match->{location}->{start};
		$end = $match->{location}->{end};

		# Print Pfam accession
	        print "   PFAM $acc\n";

   		# Check if this Pfam is already included in database for this protein
   		$statement = "SELECT EXISTS (SELECT pfam_id, prot_id FROM PFAM_FEATS WHERE pfam_id=\"$acc\" AND prot_id=\"$protID\" AND start_aa=\"$start\");";
   		my @response = $dbh->selectrow_array($statement);
		next if($response[0]);

		# Include Pfam in list of domains
		$pfams = $pfams.$acc.";";
	
		# Retrieve Pfam information for this domain
		$xmlURL = "http://pfam.xfam.org/family/$acc?output=xml";
		$data = $xml->XMLin(get($xmlURL), KeyAttr => { package => 'go_id' });	

		# 1) Clan identifier if exists
		$clan = $data->{entry}->{clan_membership}->{clan_acc} if $data->{entry}->{clan_membership};
		$ontologies = $data->{entry}->{go_terms}->{category};	             

		# 2) GO terms
		$ontologies = [$ontologies] if ref($ontologies) eq "HASH";
	        foreach my $ontology (@{$ontologies})
	        {
		    my $onto = $ontology->{name};
                    $onto = uc substr $onto,0,1;
		
		    my $terms = $ontology->{term};
		    $terms = [$terms] if ref($terms) eq "HASH";
	            foreach my $term (@{$terms})
	            {	
			$term = $term->{go_id};
			$term = substr $term,3;
	    		$GOterms = $GOterms."$onto:$term;";
		    }
	        }			

		# Save information in Pfam table
		$statement = "INSERT INTO PFAM_FEATS (prot_id, pfam_id, pfam_seq, pfam_type, start_aa, end_aa, pfam_clan, gos) VALUES (\'".$protID."\', \'".$acc."\', \'".$sequence."\', \'".$type."\', \'".$start."\', \'".$end."\', \'".$clan."\', \'".$GOterms."\');";
		$rv  = $dbh->do($statement);
	
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
