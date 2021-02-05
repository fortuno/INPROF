use strict;
use warnings;
use XML::Simple;
use LWP;
use Data::Dumper;
use REST::Client;
use URI::Encode;
use JSON;

my $workdir = "/home/cased/Inprof";

require "$workdir/MYSQL_FEAT_DDBB/aln_seqs.pl";

sub add_pdb_entry {
   
   # Read arguments
   my $pdb = $_[0];
   my $prot = $_[1];
   my $inChains = $_[2];
   my $dbh = $_[3];   
   my $debug = $_[4]; 
   
   # Check this PDB is already included in database
   my $statement = "SELECT EXISTS (SELECT * FROM PDB_FEATS WHERE pdb_id=\"$pdb\" AND prot_id=\"$prot\");";
   my @response = $dbh->selectrow_array($statement);

   # Return if this PDB entry already exists
   if($response[0]) 
	{return}

   print "   PDB $pdb\n";

   # Create object
   my $ua = LWP::UserAgent->new;

   # Save PDB file from PDB website
   my $pdbURL = "https://files.rcsb.org/download/$pdb.pdb";
   my $PDBfile = "$workdir/MYSQL_FEAT_DDBB/temp_pdb/$pdb.pdb";
   getstore($pdbURL, $PDBfile) if ! -f $PDBfile;

   # Generate DSSP file and retrieve table
   my $dsspRes = `/var/www/scoring/ws/dssp-2.0.4-linux-amd64 -i $PDBfile`;
   ($dsspRes) = $dsspRes =~ m/X-CA   Y-CA   Z-CA(.*)/s;  

   # Save sequences from PDB website
   $pdbURL = "https://www.rcsb.org/fasta/entry/$pdb";
   my $FASTAfile = "$workdir/MYSQL_FEAT_DDBB/temp_pdb/$pdb.fasta";
   getstore($pdbURL, $FASTAfile) if ! -f $FASTAfile;

   # Read PDB sequences
   my $seqio = Bio::SeqIO->new(-file => $FASTAfile, '-format' => 'Fasta');

   # Read HTML from Pfam website for PDB structure
   my $pfamURL = "http://pfam.xfam.org/structure/$pdb#tabview=tab3";
   my $req = HTTP::Request->new( GET => $pfamURL );
   my $res = $ua->request($req); 
   my $content = $res->content;

   ($content) = $content =~ m#<table id="structuresTable"(.*?)</table>#s;
   ($content) = $content =~ m#<tbody>(.*?)</tbody>#s if $content;
   my @matches = $content =~ m#<tr class=(.*?)</tr>#gs if $content;
   
   # Create hash table with Pfam information for each chain
   my %pdb_pfam;
   if ($content)
   {
      foreach my $string (@matches)
      {
          my @rows = $string =~ m#<td>(.*?)</td>#gs;    
          ($pdb_pfam{$rows[0]}{'protein'}) = $rows[3] =~ m#">\n\s+(.*?)</a>#s;  
          ($pdb_pfam{$rows[0]}{'pfam'})= $rows[6] =~ m#/family/(.*?)">#s;
      } 
   }
   else
   {
	print "WARNING - There is no Pfam information associated to the $pdb structure \n";
   }


   # We find each "Chain" in sequences
   while (my $fastaSeq=$seqio->next_seq)
   {
	# Retrieve the "Chain" field
        my $sequence = $fastaSeq ->seq;
        my $chain_id = $fastaSeq ->desc;
        ($chain_id) = $chain_id =~ /(\w+)(\||,)/;

	# Jump chain if it is a RNA chain or it is not included in the protein
	if ($fastaSeq->alphabet ne "protein" | !($inChains =~ /$chain_id/)) 
	     {next;}

	# Print PDB entry
	print "     Chain $chain_id\n";

  # Prepare GraphQL query for GO terms
  my $querygraphql = "{
    polymer_entity_instances(instance_ids:[\"$pdb.$chain_id\"]) {
       polymer_entity {
          rcsb_polymer_entity_annotation {
              annotation_id
              name
              type
              annotation_lineage{
                  id
                  name
              }
          }
       }
    }
  }";
  my $encoder = URI::Encode->new({double_encode => 0});
  $querygraphql = $encoder->encode($querygraphql, 1);

  # Get GO terms from API
  my $pdbGOURL = "https://data.rcsb.org/graphql?query=$querygraphql";
  my $client = REST::Client->new();
  $client->GET($pdbGOURL);
  my $response = from_json($client->responseContent());

  my $terms =";";
  foreach my $instance ($response->{data}->{polymer_entity_instances}){
     for my $entity (@$instance){
        foreach my $annotation ($entity->{polymer_entity}->{rcsb_polymer_entity_annotation}){
            for my $term (@$annotation){
               if ($term->{type} eq "GO"){
                  my $lineage = $term->{annotation_lineage};
                  my $ontology = "";
                  for my $subterm (@$lineage){
                      #print $subterm->{id}."\t".$subterm->{name}."\n";
                      if ($subterm->{name} eq "biological_process"){
                         $ontology="BP";
                      } elsif ($subterm->{name} eq "cellular_component"){ 
                         $ontology="CC";
                      } elsif ($subterm->{name} eq "molecular_function"){
                         $ontology="MF";
                      }
                  }
                  $term = $term->{annotation_id};
                  $term =~ s/GO/$ontology/g; 
                  $terms = $terms.$term.";";
               }
            }
        }
     }
  }

	# Use Pfam information previously obtained
	my $pfam = "";
        $pfam = $pdb_pfam{$chain_id}{'pfam'} if $pdb_pfam{$chain_id};      
        my $prot_id = $prot;
   
	# Find DSSP secondary structure for this chain
	my $ss = "";
        my $seq = "";
	if ($dsspRes)
        {
	    my @dssp_seq = $dsspRes =~ m/\n.{11}$chain_id.(\w)/gs; 
	    my @sec_seq = $dsspRes =~ m/\n.{11}$chain_id.{4}(\w|\s)/gs;
            $seq = join("", @dssp_seq);
            $ss = join("", @sec_seq);
	}

        # Reunifying secondary structure types in helix (H), strand(E) and turn (T)
        $ss =~ s/(I|G)/H/g; # All the helix types
        $ss =~ s/B/E/g; # All the strand types
        $ss =~ s/(\s|S)/U/g; # Unknown secondary structure
           
	# Consider those PDB without secondary structure in DSSP
	if($ss eq "")
	{
	    $seq=$sequence;
	    $ss=$sequence;
	    $ss =~ s/\w/U/g;
        }

	# Avoid structures with extremely short sequences
        if(length($sequence)>5)
        {
                if(substr($sequence,0,20) ne substr($seq,0,20) | length($sequence) ne length($seq))
            	{
                    print "WARNING - There was an incoherence between PDB and DSSP sequences\n";

		    if($debug){
	            	print "DSS:$seq\n";
	            	print "SSD:$ss\n";
                    }

                    # We try to align PDB and DSSP sequences to see their differences
		    # and transform the secondary structure according to the PDB sequence
                    $ss = align_sequences($sequence, $seq, $ss);

		    if($debug){
	            	print "PDB:$sequence\n";
	            	print "SSP:$ss\n";
                    }

		    die "Sequence in DSSP is longer\n" if length($seq)>length($sequence);

                }

	   	# Save information in Pfam table
           	my $statement = "INSERT INTO PDB_FEATS (pdb_id, pdb_chain, pdb_seq, prot_id, pfams, gos, seq_secondary) VALUES (\'".$pdb."\', \'".$chain_id."\', \'".$sequence."\', \'".$prot_id."\', \'".$pfam."\', \'".$terms."\', \'".$ss."\');";
	   	my $rv  = $dbh->do($statement);

	}
   }

   return;
}

1;
