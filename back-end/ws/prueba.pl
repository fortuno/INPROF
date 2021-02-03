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

require "shared_features.pl";
require "find_matches.pl";
require "seq_to_align.pl";
require "match_arrays.pl";
require "match_contacts.pl";
require "getLoggingTime.pl";

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
    print "Sorry! The input format is wrong! Please check you have introduced a list of correct protein IDs or a correct FASTA format including both protein IDs and sequences\n";
    unlink $file;
    exit(-1);
}

# Connecting to database
my $data_source="dbi:mysql:protein_ddbb:localhost";
my $dbh = DBI->connect($data_source, 'reader', 'protint') or die $DBI::errstr;

# Check which IDs are included in the database
my $statement = "SELECT prot_id FROM UNIPROT_FEATS WHERE prot_id IN (\'".join('\',\'',@ids)."\');";
my @response = @{$dbh->selectcol_arrayref($statement)};
my @diff = array_diff(@ids, @response);


# Check if they are Uniprot accessions
$statement = "SELECT prot_id, acc_uniprot FROM UNIPROT_FEATS WHERE "; 
foreach my $accession (@diff)
{
   $statement .= "acc_uniprot LIKE '%$accession%' OR ";
}
$statement = substr($statement,0,-4).";";
@response = @{$dbh->selectall_arrayref($statement)};
my @ids_acc = map $_->[ 0 ], @response;
my $acc_acc = join (" ", (map $_->[ 1 ], @response));

my @diff2;
foreach my $accession (@diff)
{
   push @diff2, $accession if !($acc_acc =~ m/$accession/);
}

print join(" ",@diff2);

