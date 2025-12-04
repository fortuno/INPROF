use strict;
use warnings;
use DBI;
use Getopt::Long;
use Bio::SeqIO;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::Tools::Run::Alignment::TCoffee;
use Bio::Tools::Run::Alignment::Muscle;
use Data::Dumper;
use Array::Utils qw(:all);
use List::MoreUtils qw(uniq);
use List::Util qw(reduce sum);
use Switch;

require "./shared_features.pl";
require "./find_matches.pl";
require "./seq_to_align.pl";
require "./match_arrays.pl";
require "./match_contacts.pl";
require "./getLoggingTime.pl";
require "./uniprot_mapping.pl";

# Read arguments
my $file = "";
my $text = "";
my $alTool = "none";
my $seqFeats = "true";
my $aaFeats = "true";
my $domFeats = "true";
my $ssFeats = "true";
my $tsFeats = "true";
my $goFeats = "true";
my $temporal = "";
my $result = GetOptions ("file=s" => \$file,
			 "text=s" => \$text,
			 "tool=s" => \$alTool,
			 "sequences=s" => \$seqFeats,
			 "aatypes=s" => \$aaFeats,
			 "domains=s" => \$domFeats,
			 "secondary=s" => \$ssFeats,
			 "tertiary=s" => \$tsFeats,
			 "go=s" => \$goFeats,
			 "temp=s" => \$temporal);

# Get time to incorporate to file names
my $runtime = getLoggingTime();

my $protIDs = "";
my %sequences;
my @ids;

# If include any file
if($file ne ""){

    # Open file
    open FILE, $file or die "Cannot open file $file : $!";
    $protIDs = do { local $/; <FILE> };
    close FILE;

    # Check if file is including sequences in FASTA format or only IDs
    if($protIDs =~ m/>/)
    {

        my $seqio;
        eval {
           # Read Fasta file
           $seqio = Bio::SeqIO->new(-file => $file, '-format' => 'Fasta');  
        
           # Retrieve sequences and protein ids
	   while(my $seq = $seqio->next_seq) 
           {
	        my $seqID = $seq->primary_id;
	        push @ids, $seqID;
	        $sequences{$seqID} = $seq->seq;

 		 die unless $sequences{$seqID} ne "";
           }
        };

    }
    # If not, is including protein IDs
    else
    {
	@ids = split /[\s|\n]+/, $protIDs;
    }
}
# If no file included
else
{
    # Read include text area
    $protIDs = $text;

    # Check if text is including sequences in FASTA format or only IDs
    if($protIDs =~ m/>/)
    {
   	# Save sequences in a file
	$file = "./uploads/sequences$runtime.txt";
   	open(my $fh, '>', $file);
   	print $fh $protIDs;
   	close $fh;

	eval {
		# Read Fasta file
		my $seqio = Bio::SeqIO->new(-file => $file, '-format' => 'Fasta');     
		while(my $seq = $seqio->next_seq) 
		{
		   my $seqID = $seq->primary_id;
		   push @ids, $seqID;
		   $sequences{$seqID} = $seq->seq;

		   die unless $sequences{$seqID} ne "";
		}
	};

    }
    # If not, is including protein IDs
    else
    {
	@ids = split /[\s|\n]+/, $protIDs;
    }
}

# Throw message error and exit if errors occurred
if( $@ ) { 
    print "Sorry! The input format is wrong. Please check you have introduced a correct FASTA format including both protein entry names and sequences\n";
    unlink $file;
    exit(-1);
}

# Checking if all IDs exist in Uniprot
my @diff;
eval{

    # Query in batches
    my $remain = $#ids;
    my $unids;
    my @mapeo;
    my $batch = 0;
    my $bsize = 400;
    while($remain > 0)
    {
        my $start = ($bsize*$batch);
        my $end;
        if ( $remain < $bsize ) {
           $end = $bsize*$batch + $remain;
        }
        else {
           $end = $bsize*($batch+1) - 1;
        }
        my @subids = @ids[$start..$end];
        $unids = join ",", @subids;
        # print("$start-$end\n");
        # print("$unids\n");
        my @subset = uniprot_mapping($unids);
        push @mapeo, @subset;
        $remain = $remain - $bsize;
        $batch += 1; 
    }

    my @mapeoFrom;
    my @mapeoTo;
    foreach (@mapeo){
       my $from = $_->{"from"};
       my $newid = $_->{"to"}->{"uniProtkbId"};
       push @mapeoFrom, $from;
       push @mapeoTo, $newid;
    }

    @diff = array_diff(@ids, @mapeoFrom);
    @ids = @mapeoTo; 
    die if @diff;
};

# Throw message error if any ID has not been found
if( $@ ) { 
    print "Sorry! Some proteins IDs have not been found in Uniprot: <strong>".join(" ",@diff)."</strong><br/> Please, check you have used correct protein entry names according to the UniProtKB format.";
    print $@;
    print "---------------------";
    unlink $file;
    exit(-1);
}

# Connecting to database
my $data_source="dbi:mysql:protein_ddbb:localhost";
my $dbh = DBI->connect($data_source, 'reader', 'protint') or die $DBI::errstr;

# Check which IDs are included in the database
my $statement = "SELECT prot_id FROM UNIPROT_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
my @response = @{$dbh->selectcol_arrayref($statement)};
@diff = array_diff(@ids, @response);

# If there are proteins not included in database, they are previously included
if (@diff)
{
   my $newfile = "/home/usuario/Documentos/MYSQL_FEAT_DDBB/tmp_new/new_proteins$runtime.txt";
   open(my $fh, '>', $newfile);
   print $fh join(' ',@diff);
   close $fh;
   my $res = `perl /home/usuario/Documentos/MYSQL_FEAT_DDBB/create_feat_ddbb.pl -f=$newfile -add=1`;
   unlink $newfile;
}

# Recheck that proteins are now included
eval{
   $statement = "SELECT prot_id FROM UNIPROT_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
   @response = @{$dbh->selectcol_arrayref($statement)};
   @diff = array_diff(@ids, @response);
   die unless $#ids == $#response;
};

# Throw message error if any ID has not been found
if( $@ ) { 
    print "Sorry! Some proteins could not be retrieved from Uniprot: <strong>".join(" ",@diff)."</strong><br/> Please, check they are correctly included in the UniProtKB database with the same ID.";
    print $@;
    print "---------------------";
    unlink $file;
    exit(-1);
}

# Retrieve required data from database
my @featArray;
push @featArray, "prot_id";
push @featArray, "seq_uniprot";
push @featArray, "pfams";
push @featArray, "seq_secondary";
push @featArray, "pdbs";
push @featArray, "gos";
$statement = join ",", @featArray;
$statement = "SELECT $statement FROM UNIPROT_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
@response = @{$dbh->selectall_arrayref($statement)};
	
# Initialize arrays for sequences and metrics
my @seq_array;
my @metrics = (0) x 54;  	# Total number of features
my @featPos; 			# Positions of selected features 
my @lenSeq;			# Array with sequence lengths
my @domains;			# Array for domains
my @goTerms;			# Array for ontological terms
my %ssArray;			# Hash for secondary structure sequences.
my %domArray;			# Hash for domain sequences.
my %domAArray;			# Hash for Pfam-A domain type sequences.
my %domBArray;			# Hash for Pfam-B domain type sequences.
my %clanArray;			# Hash for clan sequences.

# Include accession names
my @accnames = (" ") x 54;

################################################### 
# FEATURES RELATED TO PROTEIN AND SEQUENCES
###################################################

# Number of proteins
my $numSeqs = $#ids+1;
$metrics[0]=$numSeqs;
$accnames[0] = join ",",@ids;

# Save sequences in file if they are not saved
if (!%sequences) {
  %sequences = map { $_->[ 0 ] => $_->[ 1 ] } @response;

  $file = "./uploads/sequences$runtime.txt";
  open(my $fh, '>', $file);
  foreach my $key (keys %sequences)
      { print $fh ">$key\n".$sequences{$key}."\n\n";} 	
  close $fh;
}

# Total number of AAs
my $numAAs = length(join("",values(%sequences)));

# Access to each entry in the database
my $posSeq = 0;
foreach my $entry (@response)
{
   # Obtain features
   my @features = @{$entry};

   # Obtain protein id and sequence
   my $pId = $features[0];
   my $sequence = $features[1];

   # Initialize vector of domains for this protein  
   my @initDom = ('') x length($sequence);
   $domArray{$pId} = \@initDom; 
   $domAArray{$pId} = \@initDom;
   $domBArray{$pId} = \@initDom;
   $clanArray{$pId} = \@initDom;    

   # Read sequence and add it for a possible future alignment
   my $seqbio = Bio::Seq->new(-seq => $sequence, -id  => $pId, -display_id  => $pId, -primary_id  => $pId);  
   push (@seq_array, $seqbio);
   $posSeq++;

   # 1) Sequence statistical metrics 
   if ($seqFeats eq "true"){ 
       my $len = length($sequence);
       $metrics[1] += $len/$metrics[0]; # Average length of sequences
       if ($metrics[2]<$len)
	{
	    $metrics[2] = $len; # Max length of sequences
	    $accnames[2] = $pId;
	}
	if ($metrics[3]==0 || $len<$metrics[3])
	{
           $metrics[3] = $len; # Min length of sequences
	    $accnames[3] = $pId;	
       }		
       push (@lenSeq, $len); # To calculate variance     
   }

   # 2) Aminoacid Types metrics
   if($aaFeats eq "true"){
       $metrics[5] += ($sequence =~ tr/G|A|P|V|L|I|M//)/$numSeqs; # Number of polar AA per sequence
       $metrics[6] += ($sequence =~ tr/S|T|C|N|Q//)/$numSeqs;     # Number of non-polar AA per sequence
       $metrics[7] += ($sequence =~ tr/K|R|H//)/$numSeqs; 	  # Number of basic AA per sequence
       $metrics[8] += ($sequence =~ tr/F|W|Y//)/$numSeqs; 	  # Number of aromatic AA per sequence
       $metrics[9] += ($sequence =~ tr/D|E//)/$numSeqs; 	  # Number of acid AA per sequence
   }

   # 3) Secondary Structure metrics
   if($ssFeats eq "true"){
       my $ssSeq = $features[3];
       $ssSeq = substr($ssSeq,0,length($sequence));	# PROVISIONAL HASTA CORREGIR BBDD!!!!
       $ssArray{$pId} = $ssSeq; 
       $metrics[22] += ($ssSeq =~ tr/H//)/$numAAs;	# % AAs in helix structure per sequence
       $metrics[23] += ($ssSeq =~ tr/E//)/$numAAs;  	# % AAs in strand structure per sequence
       $metrics[24] += ($ssSeq =~ tr/T//)/$numAAs;   	# % AAs in turn structure per sequence
       $metrics[25] += ($ssSeq =~ tr/U//)/$numAAs;   	# % AAs in unknown structure per sequence

   } 

   # Retrieve GO terms to calculate ontological metrics
   if($goFeats eq "true")
   {
       # Convert list of terms in array
       my @terms = split ";", $features[5];
       @terms = grep { $_ ne '' } @terms;

       # Save terms in global array
       push (@goTerms, @terms);
   }

}
$metrics[4] = (sum map { ($_ - $metrics[1])**2 } @lenSeq) / ($numSeqs-1); # Calculate variance
push(@featPos, (0..4)) if $seqFeats eq "true";
push(@featPos, (5..9)) if $aaFeats eq "true";
push(@featPos, (22..25)) if $ssFeats eq "true";

# 4) Pfam domain metrics
my @domF;
if($domFeats eq "true")
{
   # Access Pfam table to incorporate domain information
   $statement = "SELECT pfam_id, pfam_seq, pfam_type, pfam_clan, start_aa, end_aa, prot_id FROM PFAM_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
   @domF = @{$dbh->selectall_arrayref($statement)};	

   # Retrieve domain features from this table
   my @pfamsA;
   my @pfamsB;
   my @pfams;
   my @clans; 
   foreach my $dom (@domF)
   {
	# Collect domains
	my @domain = @{$dom};
	push(@pfamsA, $domain[0]) if $domain[2] eq "A"; # Pfam-A domains
	push(@pfamsB, $domain[0]) if $domain[2] eq "B"; # Pfam-B domains	
	push(@pfams, $domain[0]);			# Pfams domains
	push(@clans, $domain[3]) if $domain[3] ne "";   # Clans

	# Calculate metrics
	$metrics[10] += ($domain[5]-$domain[4]+1)/$numAAs if $domain[2] eq "A"; # % AA in Pfam-A
	$metrics[11] += ($domain[5]-$domain[4]+1)/$numAAs if $domain[2] eq "B"; # % AA in Pfam-B	
	$metrics[12] += ($domain[5]-$domain[4]+1)/$numAAs;		        # % AA in any Pfam.
	$metrics[13] += ($domain[5]-$domain[4]+1)/$numAAs if $domain[3] ne "";  # % AA in any Clan.

	# Save domain sequences for a possible future alignment
        my @domSeq = @{$domArray{$domain[6]}};
        my @domASeq = @{$domArray{$domain[6]}};
        my @domBSeq = @{$domArray{$domain[6]}};
	my @domAdd = ($domain[0]) x ($domain[5]-$domain[4]+1);
        splice @domSeq, $domain[4], ($domain[5]-$domain[4]+1), @domAdd;
        splice @domASeq, $domain[4], ($domain[5]-$domain[4]+1), @domAdd if $domain[2] eq "A";
        splice @domASeq, $domain[4], ($domain[5]-$domain[4]+1), @domAdd if $domain[2] eq "B";
	$domArray{$domain[6]} = \@domSeq;
	$domAArray{$domain[6]} = \@domASeq;
	$domBArray{$domain[6]} = \@domBSeq; 

	# Save clan sequences for a possible future alignment
        my @clanSeq = @{$clanArray{$domain[6]}};
	my @clanAdd = ($domain[3]) x ($domain[5]-$domain[4]+1);
        splice @clanSeq, $domain[4], ($domain[5]-$domain[4]+1), @clanAdd;
	$clanArray{$domain[6]} = \@clanSeq;   
   }

   $metrics[14] = ($#pfamsA+1)/$numSeqs; # Num Pfam-A per seq
   $metrics[15] = ($#pfamsB+1)/$numSeqs; # Num Pfam-B per seq
   $metrics[16] = ($#pfams+1)/$numSeqs;  # Num Pfams per seq
   $metrics[17] = ($#clans+1)/$numSeqs;  # Num Clans per seq
   $accnames[14] = join ",", uniq(@pfamsA);
   $accnames[15] = join ",", uniq(@pfamsB);
   $accnames[16] = join ",", uniq(@pfams);
   $accnames[17] = join ",", uniq(@clans);

   ($metrics[18], $accnames[18]) = shared_features(\@pfamsA, $numSeqs); # Shared Pfam-A per seq
   ($metrics[19], $accnames[19]) = shared_features(\@pfamsB, $numSeqs); # Shared Pfam-B per seq
   ($metrics[20], $accnames[20]) = shared_features(\@pfams, $numSeqs);  # Shared Pfams per seq
   ($metrics[21], $accnames[21]) = shared_features(\@clans, $numSeqs);  # Shared Clans per seq
   
   push(@featPos, (10..21));
}

# 5) PDB tertiary structure metrics
my @pdbF;
my $confile;
my $contacts; 
if($tsFeats eq "true")
{
   # Access PDB table to incorporate domain information
   $statement = "SELECT pdb_id, prot_id, pdb_chain FROM PDB_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
   @pdbF = @{$dbh->selectall_arrayref($statement)};	

   # Retrieve 3D structure features from this table 
   my @pdbs; 
   my @prot_pdb;
   my $conText = "";
   foreach my $pdb (@pdbF)
   {
	# Collect structures
	my @structs = @{$pdb};
	push(@pdbs, $structs[0]." ".$structs[1]);
	push(@prot_pdb, $structs[1]);

	# Write connection file for future STRIKE
        my $pdbfile = "/home/usuario/Documentos/MYSQL_FEAT_DDBB/temp_pdb/".$structs[0]."\.pdb";
        if (-f $pdbfile){
	    $conText .= $structs[1]." ".$pdbfile." ".$structs[2]."\n";
        }
   }

   # Save file with connections
   $confile = "./con_files/pdb_connections$runtime.con";
   open(my $fh, '>', $confile);
   print $fh $conText;
   close $fh; 

   # Retrieve only PDB identifiers
   my @uniqPDBs = uniq (@pdbs);

   @pdbs = ();
   foreach my $pdb (@uniqPDBs)
   	{push (@pdbs, substr($pdb,0,4));} 

   # Calculate metrics
   $metrics[26] = ($#pdbs+1)/$numSeqs; 	       				# Num PDB structures per sequence
   $accnames[26] = join ",", uniq(@pdbs);  
   $metrics[27] = scalar(uniq @prot_pdb)/$numSeqs;    			# % Sequences with any PDB	
   ($metrics[28], $accnames[28]) = shared_features(\@pdbs, $numSeqs);  	# Shared PDB structures
	
   $contacts= `/home/usuario/Documentos/strike_contacts/bin/strike_contacts -a $file -c $confile -n --nc 4`;
   $metrics[29] = ($contacts =~ tr/\n//) / $numSeqs;		# Number of contacts per sequence  

   push(@featPos, (26..29));
}

# 6) Ontological metrics
if($goFeats eq "true")
{
   # Join terms
   my $terms = join(",",@goTerms);

   # Calculate metrics
   $metrics[30] = ($#goTerms+1) / $numSeqs;		# Number of terms per sequence
   $metrics[31] = ($terms =~ tr/F//) / $numSeqs;	# Number of MF terms per sequence
   $metrics[32] = ($terms =~ tr/C//) / $numSeqs;	# Number of CC terms per sequence
   $metrics[33] = ($terms =~ tr/P//) / $numSeqs;	# Number of BP terms per sequence
   $accnames[30] = join ",", uniq(@goTerms);  
   $accnames[31] = join ",", grep(/F/i, uniq(@goTerms));  
   $accnames[32] = join ",", grep(/C/i, uniq(@goTerms));  
   $accnames[33] = join ",", grep(/P/i, uniq(@goTerms));   

   ($metrics[34], $accnames[34]) = shared_features(\@goTerms, $numSeqs);	# Number of shared terms per sequence

   push(@featPos, (30..34));
}

################################################### 
# FEATURES RELATED TO ALIGNMENTS
###################################################

if($alTool ne "none")
{
	# Peform the alignment according to the selected tool
	my @params;  
	my $factory;
	switch ($alTool) {
		case "clustalw"{ 
		   @params = ('ktuple' => 4, 'matrix' => 'Gonnet', 'quiet' => 1); 
		   $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params); 
		}
		case "tcoffee"{
		   @params = ('ktuple' => 4, 'matrix' => 'blosum', 'quiet' => 'nothing'); 
		   $factory = Bio::Tools::Run::Alignment::TCoffee->new(@params);
		}
		case "muscle"{ 
		   @params = ('quiet' => 1, 'maxiters' => 2); 
		   $factory = Bio::Tools::Run::Alignment::Muscle->new(@params); 
		}
		else{ 
		   @params = ('ktuple' => 4, 'matrix' => 'Gonnet', 'quiet' => 1); 
		   $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params); 
		}
	}

	# Perform alignment
	my $aln = $factory->align(\@seq_array); 

        # my $pruebafile = "./uploads/prueba".$temporal.".msf";
	# my $out = Bio::AlignIO->new(-file => ">$pruebafile", -format => 'msf');
	# $out->write_aln($aln);

	# Calculate total possible matches, length of the alignment and total size
	my $fistSeq = $aln->get_seq_by_pos(1)->{seq};
	my $comp = (lc $fistSeq ^ lc $fistSeq);
	my $lengthAlign = length($fistSeq);
	my $totalSize = $lengthAlign*$numSeqs;
	my $totalMatches = 0;
        my $totalContacts = 0;


	# Select each sequence in the alignment
	for (my $i=1; $i <= $numSeqs; $i++) {

	   # Read one sequence
	   my $seq1 = $aln->get_seq_by_pos($i)->{seq};
	   my $id1 = $aln->get_seq_by_pos($i)->id;

	   # Change the sequence names in the alignment
	   my $alnID = $aln->get_seq_by_pos($i)->get_nse;
	   $aln->displayname($alnID,$id1);

	   for(my $j=$i+1; $j <= $numSeqs; $j++){

	       	# Read remaining sequences aligned to the previous one.
	       	my $seq2 = $aln->get_seq_by_pos($j)->{seq};
		my $id2 = $aln->get_seq_by_pos($j)->id;
		$seq2 =~ tr/\.|\-/\:/;

	 	# Total of possible matches
		$totalMatches += length($seq1);

		# 1) Calculate alignment metrics
		$metrics[35] += ((lc $seq1 ^ lc $seq2) =~ tr/\0//);       
		$comp = $comp | (lc $seq1 ^ lc $seq2) if $i==1;

		# 2) Aminoacid Types metrics
		if($aaFeats eq "true"){
		   
		   # Calculate metrics
		   my @chars = ('G','A','P','V','L','I','M');
		   $metrics[38] += find_matches($seq1,$seq2,\@chars); # Matches in polar AAs
		   @chars = ('S','T','C','N','Q');
		   $metrics[39] += find_matches($seq1,$seq2,\@chars); # Matches in non-polar AAs
		   @chars = ('K','R','H');
		   $metrics[40] += find_matches($seq1,$seq2,\@chars); # Matches in basic AAs
		   @chars = ('F','W','Y');
		   $metrics[41] += find_matches($seq1,$seq2,\@chars); # Matches in aromatic AAs
		   @chars = ('D','E');
		   $metrics[42] += find_matches($seq1,$seq2,\@chars); # Matches in acid AAs
		}

		# 3) Domain metrics
		if($domFeats eq "true"){

		   # Convert domains sequence according to the alignment.
                   # printf "PRUEBA ".$id1." ".$id2."\n";
		   my @domseq1 = @{$domArray{$id1}};
		   my @domseq2 = @{$domArray{$id2}};
		   @domseq1 = @{seq_to_align(\@domseq1, $seq1)};
		   @domseq2 = @{seq_to_align(\@domseq2, $seq2)};

		   # Convert domains types (Pfam-A and Pfam-B) sequence according to the alignment.
		   my @domAseq1 = @{$domAArray{$id1}};
		   my @domAseq2 = @{$domAArray{$id2}};
		   @domAseq1 = @{seq_to_align(\@domAseq1, $seq1)};
		   @domAseq2 = @{seq_to_align(\@domAseq2, $seq2)};
		   my @domBseq1 = @{$domBArray{$id1}};
		   my @domBseq2 = @{$domBArray{$id2}};
		   @domBseq1 = @{seq_to_align(\@domBseq1, $seq1)};
		   @domBseq2 = @{seq_to_align(\@domBseq2, $seq2)};

		   # Convert clan sequence according to the alignment.
		   my @clanseq1 = @{$clanArray{$id1}};
		   my @clanseq2 = @{$clanArray{$id2}};
		   @clanseq1 = @{seq_to_align(\@clanseq1, $seq1)};
		   @clanseq2 = @{seq_to_align(\@clanseq2, $seq2)};

	 	   # Calculate metrics
		   $metrics[43] += match_arrays(\@domseq1, \@domseq2);   # Matches in domains  
		   $metrics[44] += match_arrays(\@domAseq1, \@domAseq2); # Matches in Pfam-A domains
		   $metrics[45] += match_arrays(\@domBseq1, \@domBseq2); # Matches in Pfam-B domains
		   $metrics[46] += match_arrays(\@clanseq1, \@clanseq2); # Matches in clans
		}

		# 4) Secondary Structure metrics
		if($ssFeats eq "true"){
		   
		   # Convert secondary structure sequence according to the alignment.
		   my $ss1 = $ssArray{$id1};
		   my $ss2 = $ssArray{$id2};
		   $ss1 = seq_to_align($ss1, $seq1);
		   $ss2 = seq_to_align($ss2, $seq2);

		   # Calculate metrics
		   my @chars = ('H');
		   $metrics[47] += find_matches($ss1,$ss2,\@chars); # Matches in helix secondary structure
		   @chars = ('E');
		   $metrics[48] += find_matches($ss1,$ss2,\@chars); # Matches in strand secondary structure
		   @chars = ('T');
		   $metrics[49] += find_matches($ss1,$ss2,\@chars); # Matches in turn secondary structure
		   @chars = ('U');
		   $metrics[50] += find_matches($ss1,$ss2,\@chars); # Matches in unknown secondary structure
		}

	        # 5) Tertiary Structure metrics
		if($tsFeats eq "true"){
		
		   # Retrieve contacts for the two sequences we are working with
		   my $contacts1 = join ("",($contacts =~ /$id1\s\d+\s\d+\n/g));
		   my $contacts2 = join ("",($contacts =~ /$id2\s\d+\s\d+\n/g));

		   # Retrieve number of matches for these two sequences
		   my $conmatch = 0;
		   my $totalcon = 0;
	           if ($contacts1 ne "" && $contacts2 ne "")
		      {($conmatch, $totalcon) = match_contacts($seq1, $seq2, $contacts1, $contacts2);} 
		   $metrics[52] += $conmatch;
		   $totalContacts += $totalcon;
		}
	   }

	   # 1) Calculate other alignment metrics
	   $metrics[36] += ($seq1 =~ tr/\.|\-//);  # Number of gaps
	}

	# Save alignment
	my $alnfile = "./results/align".$temporal.".msf";
	my $out = Bio::AlignIO->new(-file => ">$alnfile", -format => 'msf');
	$out->write_aln($aln);

	# Divide metrics by total of possible matches
	$metrics[35] = $metrics[35]/$totalMatches;
	$metrics[36] = $metrics[36]/$totalSize;
	$metrics[37] = (($comp) =~ tr/\0//)/$lengthAlign;
	push(@featPos, (35..37));

	if($aaFeats eq "true"){
	   $metrics[38] = $metrics[38]/$totalMatches;
	   $metrics[39] = $metrics[39]/$totalMatches;
	   $metrics[40] = $metrics[40]/$totalMatches;
	   $metrics[41] = $metrics[41]/$totalMatches;
	   $metrics[42] = $metrics[42]/$totalMatches;
	   push(@featPos, (38..42));
	}

	if($domFeats eq "true"){
	   $metrics[43] = $metrics[43]/$totalMatches;
	   $metrics[44] = $metrics[44]/$totalMatches;
	   $metrics[45] = $metrics[45]/$totalMatches;
	   $metrics[46] = $metrics[46]/$totalMatches;
	   push (@featPos, (43..46));
	}

	if($ssFeats eq "true"){
	   $metrics[47] = $metrics[47]/$totalMatches;
	   $metrics[48] = $metrics[48]/$totalMatches;
	   $metrics[49] = $metrics[49]/$totalMatches;
	   $metrics[50] = $metrics[50]/$totalMatches;
	   $metrics[51] = $metrics[47]+$metrics[48]+$metrics[49]+$metrics[50];
	   push (@featPos, (47..51));
	}

	if($tsFeats eq "true"){

	   # STRIKE SCORE
	   my $strike = `/home/usuario/Documentos/strike_v1.1/bin/strike -a $alnfile -c $confile -n --nc 4`;
	   my @matches = ( $strike =~ /\n([\d\.\-]+)\n/g ); # Retrieve STRIKE scores

           $metrics[52] = $metrics[52]/$totalContacts if ($totalContacts ne 0);	  # Percentage of contact matches
	   $metrics[53] = 0;
           $metrics[53] = sum(@matches)/@matches if (@matches != 0); # Calculate average STRIKE
	   push (@featPos, (52..53));
	}

	# Remove temporary file with the alignment
       # unlink $alnfile;
}

###################################################
# RETURN HTML TABLE WITH SELECTED METRICS
###################################################
my $tablePos = 0;

# Headers 
my @labelIDs =('SEQ_SQ','SEQ_LG','SEQ_MX','SEQ_MN','SEQ_VA','SEQ_PL','SEQ_NP','SEQ_BS',
'SEQ_AR','SEQ_AC','SEQ_PA','SEQ_PB','SEQ_PT','SEQ_PC','SEQ_DA','SEQ_DB','SEQ_DT','SEQ_DC',
'SEQ_CA','SEQ_CB','SEQ_CT','SEQ_CK','SEQ_HX','SEQ_TD','SEQ_TN','SEQ_SU','SEQ_NS','SEQ_PS',
'SEQ_CS','SEQ_NC','SEQ_GO','SEQ_MF','SEQ_CC','SEQ_BP','SEQ_CG','MSA_ID','MSA_GP','MSA_TC',
'MSA_PL','MSA_NP','MSA_BS','MSA_AR','MSA_AC','MSA_PF','MSA_PA','MSA_PB','MSA_PC','MSA_HX',
'MSA_TD','MSA_TN','MSA_SU','MSA_SS','MSA_3D','MSA_SK');

# Categories
my @categories =(('Sequences') x 5, ('Amino-acid Types in Sequences') x 5, ('Domains in Sequences') x 12, ('Secondary Structure in Sequences') x 4, ('Tertiary Structure in Sequences') x 4, ('Ontological Terms in Sequences') x 5, ('Alignments') x 3, ('Amino-acid Types in Alignments') x 5, ('Domains in Alignments') x 4, ('Secondary Structure in Alignments') x 5, ('Tertiary Structure in Alignments') x 2);

# Descriptions
my @description =(
'Number of sequences',
'Average length of sequences',
'Maximum length of sequences',
'Minimum length of sequences',
'Variance length of sequences',
'&#35; polar amino acids per sequence',
'&#35; non-polar amino acids per sequence',
'&#35; basic amino acids per sequence',
'&#35; aromatic amino acids per sequence',
'&#35; acid amino acids per sequence',
'&#37; amino acids in Pfam-A domains',
'&#37; amino acids in Pfam-B domains',
'&#37; amino acids in any Pfam domain',
'&#37; amino acids in Pfam clans',
'&#35; Pfam-A domains per sequence',
'&#35; Pfam-B domains per sequence',
'&#35; Pfam domains per sequence',
'&#35; Pfam clans per sequence',
'&#35; Pfam-A domains shared by pairs',
'&#35; Pfam-B domains shared by pairs',
'&#35; Pfam domains shared by pairs',
'&#35; Pfam clans shared by pairs',
'&#37; amino acids in helix structures',
'&#37; amino acids in strand structures',
'&#37; amino acids in turn structures',
'&#37; amino acids in other structures',
'&#35; structures per sequence',
'&#37; sequences with PDB structures',
'&#35; PDB structures shared by pairs',
'&#35; contacts per sequence',
'&#35; GO terms per sequence',
'&#35; GO-MF terms per sequence',
'&#35; GO-CC terms per sequence',
'&#35; GO-BP terms per sequence',
'&#35; GO terms shared by pairs',
'&#37; identities in alignment',
'&#37; gaps in alignment',
'&#37; totally conserved columns in alignment',
'&#37; matches of polar amino acids',
'&#37; matches of non-polar amino acids',
'&#37; matches of basic amino acids',
'&#37; matches of aromatic aminoacids',
'&#37; matches of acid amino acids',
'&#37; matches of same Pfam domains',
'&#37; matches of same Pfam-A domains',
'&#37; matches of same Pfam-B domains',
'&#37; matches of same Pfam clans',
'&#37; matches of helix structures',
'&#37; matches of strand structures',
'&#37; matches of turn domains',
'&#37; matches of other structures',
'&#37; matches of any secondary domains',
'&#37; matches of contacts',
'&#37; STRIKE score');

# Print Json Object
@featPos = sort {$a <=> $b} @featPos;

printf "[\n";

foreach my $pos (@featPos)
{
   $tablePos++;
   
   if ($tablePos < @featPos)
   	{printf "{\"Number\": \"$tablePos\",\n\"ID\": \"".$labelIDs[$pos]."\",\n\"Value\": \"%.3f\",\n\"Category\": \"".$categories[$pos]."\",\n\"Description\": \"".$description[$pos]."\",\n\"Links\": \"".$accnames[$pos]."\"},\n", $metrics[$pos];}
   else
	{printf "{\"Number\": \"$tablePos\",\n\"ID\": \"".$labelIDs[$pos]."\",\n\"Value\": \"%.3f\",\n\"Category\": \"".$categories[$pos]."\",\n\"Description\": \"".$description[$pos]."\",\n\"Links\": \"".$accnames[$pos]."\"}]\n", $metrics[$pos];}
	

   # For HTML table (just in case)
   # printf "<tr class=\"info\" id=\"".$labelIDs[$pos]."\">\n";
   # printf "   <td width=\"10\">$tablePos</td>\n";
   # printf "   <td width=\"50\">".$labelIDs[$pos]."</td>\n";
   # printf "   <td width=\"50\">%.3f</td>\n",$metrics[$pos];
   # printf "   <td width=\"100\">".$categories[$pos]."</td>\n";
   # printf "</tr>\n";
}

# Removing temporaly files
#unlink $confile;
#unlink $file;

