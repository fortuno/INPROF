#===============================================================================
# 
# SCRIPT TO CREATE AND/OR UPDATE MYSQL DATABASE WITH PROTEIN FEATURES
#
# INPUT: 
#    --filename (-f): File with the tab-separated ids of proteins.
#    --user (-u): User to connect with MySQL database.
#    --password (-p): Password to connect with MySQL database.
#    --add (-a): "1" for adding proteins to DDBB / "0" to restore DDBB	
#    --debug (-d): show additional message for debugging purposes. 
# OUTPUT: 
#   Three tables are created in MySQL: 
#     * UNIPROT_FEATS
#     * PDB_FEATS
#     * PFAM_FEATS
#
# Dr. Francisco M. Ortuño Guzman
# fortuno@ugr
# March, 2015
#
# VERSION 
# 2015-05-06: creation
# 2015-01-07: v1.0
# 2015-09-10: v1.1
#
# USAGE:
# perl create_feat_ddbb.pl -f=<accessions_file.txt> -u=<user> -p=<password>
#
#===============================================================================
use strict;
use warnings;
use DBI;
use Getopt::Long;
use Bio::SeqIO;
use Data::Dumper;

my $workdir = "/home/cased/INPROF/back-end";

require "$workdir/MYSQL_FEAT_DDBB/pfam_subs.pl";
require "$workdir/MYSQL_FEAT_DDBB/pdb_subs.pl";

# Read accession file, user and password
my $debug = 0;
my $acc_file = "";
my $user = "";
my $psw = "";
my $add_entries = 0;
my $unifile = "";
my $result = GetOptions ("user=s" => \$user,
			 "password=s" => \$psw,
			 "filename=s" => \$acc_file,
			 "add=i" => \$add_entries,
			 "debug=i" => \$debug,
			 "uniprot=s" => \$unifile);

if($user eq "" | $psw eq ""){
   die "some mandatory arguments are not specified.\n"; 	
}


#########################################
# CREATING UNIPROT TABLE
#########################################
# Connecting to database
my $data_source="dbi:mysql:protein_ddbb:localhost";
my $dbh = DBI->connect($data_source, $user, $psw) or die $DBI::errstr;

# Create tables if database will be completely updated.
my $statement;
my $rv;
if(!$add_entries){
	print "Creating MySQL tables...";
	# Check if tables are already created and remove them:
	# 1) Table with Uniprot features
	$statement = "DROP TABLE IF EXISTS UNIPROT_FEATS;";
	$rv  = $dbh->do($statement);
	# 2) Table with Pfam features
	$statement = "DROP TABLE IF EXISTS PFAM_FEATS;";
	$rv  = $dbh->do($statement);
	# 2) Table with PDB features
	$statement = "DROP TABLE IF EXISTS PDB_FEATS;";
	$rv  = $dbh->do($statement);

	# Creating tables:
	# 1) Table with Uniprot features
	$statement = "CREATE TABLE UNIPROT_FEATS (
		prot_id VARCHAR(15), 
		acc_uniprot TEXT, 
		seq_uniprot TEXT, 
		seq_secondary TEXT, 
		pfams TEXT, 
		pdbs TEXT, 
		gos TEXT,
		PRIMARY KEY(prot_id)
	);";
	$rv  = $dbh->do($statement);
	# 2) Table with Pfam features
	$statement = "CREATE TABLE PFAM_FEATS (
		pfam_id VARCHAR(7), 
		prot_id VARCHAR(15), 
		pfam_seq TEXT, 
		pfam_type CHAR,
		pfam_clan VARCHAR(6), 
		start_aa INT, 
		end_aa INT,
		gos TEXT,
	    	PRIMARY KEY(pfam_id, prot_id, start_aa)
	);";
	$rv  = $dbh->do($statement);
	# 3) Table with PDB features
	$statement = "CREATE TABLE PDB_FEATS (
		pdb_id VARCHAR(7), 
		pdb_chain VARCHAR(2) BINARY NOT NULL,
		prot_id VARCHAR(15), 
		pdb_seq TEXT, 
		pfams TEXT, 
		gos TEXT,
		seq_secondary TEXT,        
		PRIMARY KEY(pdb_id, prot_id, pdb_chain)
	);";
	$rv  = $dbh->do($statement);
	print "DONE\n";

	# Removing synonyms
	unlink "synonyms.txt";
}

#########################################
# DOWNLOAD UNIPROT INFORMATION
#########################################
print "Retrieving Uniprot information...";
my $uniprot;
if($unifile eq ""){
   # Download features in Uniprot and save them locally
   my $uniseq = `perl $workdir/MYSQL_FEAT_DDBB/extract_sequence_uniprot.pl $acc_file > sequences.fasta`;
   $uniprot = `perl $workdir/MYSQL_FEAT_DDBB/extract_uniprot.pl $acc_file`;

   my $uniprot_file = "uniprot_features.txt";

   if (-e $uniprot_file) {} else {
	    # Use the open() function to create the file.
		unless(open FILE, '>'.$uniprot_file) {
		    # Die with error message 
		    # if we can't open it.
		    die "\nUnable to create $uniprot_file\n";
		}
   }

   open(my $fh, '>', $uniprot_file);
   print $fh $uniprot;
   close $fh;
}
else{
   # Read features of Uniprot if they are in local
   open FILE, $unifile or die "Cannot open file $unifile : $!";
   $uniprot = do { local $/; <FILE> };
   close FILE;
}
print "DONE\n";

#########################################
# INCLUDE UNIPROT INFORMATION IN DATABASE
#########################################
my $prot_id = "";
my $accs = "";
my $gos = "";
my $pdbs = "";
my $pfams = "";
my $sequence = "";
my $sec_seq = "";
my $length = 0;
my $prot_pos = -1;
my $error = 0;

# Divide annotation in lines
my @lines = split /\n/, $uniprot;

# Read protein sequences file
my $seqio = Bio::SeqIO->new(-file => "sequences.fasta", '-format' => 'Fasta');

# Retrieve information in each line
print "Updating MySQL database...\n";
foreach my $line (@lines) {

    eval{

	  if($line =~ m/^ID   (\w+)/)
	  {  
	     # Reset error flag because accessing new ID
	     $error = 0;

	     # If it is not first protein, save information of the previous one
	     if($prot_id ne "")  
	     {
		# Do not consider this protein if sequences do not match
		die "Sequence lengths in $prot_id do not match!\n" if(length($sec_seq) ne length($sequence));

		# Check this protein is already included in database
		my $statement = "SELECT EXISTS (SELECT * FROM UNIPROT_FEATS WHERE prot_id=\"$prot_id\");";
		my @response = $dbh->selectrow_array($statement);

		# Do not include entry if this protein already exists
		if(!$response[0]) 
		{
			# Save annotation for specific ID
			$statement = "INSERT INTO UNIPROT_FEATS (prot_id, acc_uniprot, seq_uniprot, seq_secondary, pfams, pdbs, gos) VALUES (\'".$prot_id."\', \'".$accs."\', \'".$sequence."\', \'".$sec_seq."\', \'".$pfams."\', \'".$pdbs."\', \'".$gos."\');";
			$rv  = $dbh->do($statement);
		}
	     }
	 
	     # Read protein accession
	     $prot_id=$1;
	     $accs=";";
	     $gos=";";
	     $pdbs=";";

	     # Print protein ID
	     print "ID: ".$prot_id."\n";

	     # Read sequence
	     my $next_seq= $seqio->next_seq; 
	     my @headers = split(/\|/,($next_seq->primary_id));
	     my $id = $headers[1];
	     $sequence = $next_seq->seq;

	     # Include Pfam entry and retrieve domain IDs
	     $pfams = add_pfam_entry($prot_id, $id, $dbh, $debug);

	     # Initialize secondary structure sequence
	     $sec_seq = 'U' x length($sequence);
	  }

         if(!$error)
         {

	     if($line =~ m/^AC   (\w+);/)
	  	{$accs=$accs.$1.";";}

	     if($line =~ m/^FT   HELIX\s+(\d+)\s+(\d+)/)
	  	{substr($sec_seq, $1-1, ($2-$1+1)) = 'H' x ($2-$1+1);}

	     if($line =~ m/^FT   TURN\s+(\d+)\s+(\d+)/)
	     	{substr($sec_seq, $1-1, ($2-$1+1)) = 'T' x ($2-$1+1);}

	     if($line =~ m/^FT   STRAND\s+(\d+)\s+(\d+)/)
	     	{substr($sec_seq, $1-1, ($2-$1+1)) = 'E' x ($2-$1+1);}

	     if($line =~ m/^DR   PDB; (\w+); ([\w\-]+); (.*); ([\w\-\=\,\ \/]+)/) # A/B= and ,
	     {
				$pdbs=$pdbs.$1.";";
                my $pdb_entry = $1;

                # Get all chains separated by '/'
                my @chains = ($4 =~ m/([\w\/]+)=/g);
                my $chain = join('/', @chains);

				add_pdb_entry($pdb_entry, $prot_id, $chain, $dbh, $debug); # if $2 ne "Model"
	     }

	     if($line =~ m/^DR   GO; GO:(\w+); (\w):/)
	  	{$gos=$gos.$1.":".$2.";";}

         }
    };

    # Catch and annotate errors
    if( $@ ){  
       print "THERE WAS AN ERROR WITH PROTEIN $prot_id : $@\n";

	# Remove possible wrong entries in databases
	$statement = "DELETE FROM PFAM_FEATS WHERE prot_id=\"$prot_id\";";
	$rv  = $dbh->do($statement); 
	$statement = "DELETE FROM PDB_FEATS WHERE prot_id=\"$prot_id\";";
	$rv  = $dbh->do($statement);          

	# Annotate error in output file
	my $er = `echo $prot_id >> errors.txt`;
	$error = 1;
    }
}

# Catch and annotate errors
if( $@ ){  
        print "THERE WAS AN ERROR WITH PROTEIN $prot_id: $@\n";

	# Remove possible wrong entries in databases
 	$statement = "DELETE FROM PFAM_FEATS WHERE prot_id=\"$prot_id\";";
	$rv  = $dbh->do($statement); 
 	$statement = "DELETE FROM PDB_FEATS WHERE prot_id=\"$prot_id\";";
	$rv  = $dbh->do($statement);          

       # Annotate error in output file
       my $errors = `echo $prot_id >> errors.txt`;
}
else{
   # Check last protein is already included in database
   $statement = "SELECT EXISTS (SELECT * FROM UNIPROT_FEATS WHERE prot_id=\"$prot_id\");";
   my @response = $dbh->selectrow_array($statement);
	  
   # Do not include entry if this protein already exists
   if(!$response[0]) 
   {
       # Save annotation for the last protein
	$statement = "INSERT INTO UNIPROT_FEATS (prot_id, acc_uniprot, seq_uniprot, seq_secondary, pfams, pdbs, gos) VALUES (\'".$prot_id."\', \'".$accs."\', \'".$sequence."\', \'".$sec_seq."\', \'".$pfams."\', \'".$pdbs."\', \'".$gos."\');";
	$rv  = $dbh->do($statement);
   }
}
print "DONE\n";
