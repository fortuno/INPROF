use strict;
use warnings;
use XML::Simple;
use LWP;
use LWP::Simple;
use Data::Dumper;
use Bio::Tools::Run::Alignment::Clustalw;

sub align_sequences {

	my $sequence1 = $_[0];
	my $sequence2 = $_[1];
	my $sorting_seq = $_[2];

	my @params = ('ktuple' => 4, 'matrix' => 'Gonnet', 'quiet' => 1); 
	my $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params);

	my @seq_array;
	my $seq1 = Bio::Seq->new(-seq => $sequence1, -id  => 'seq1');
	my $seq2 = Bio::Seq->new(-seq => $sequence2, -id  => 'seq2');
	push (@seq_array, $seq1);
	push (@seq_array, $seq2);

	my $seq_array_ref = \@seq_array;		 
	my $aln = $factory->align($seq_array_ref);

	my $aln_pdb = $aln->get_seq_by_pos(1)->{seq};
	my @aln_dssp = split("",$aln->get_seq_by_pos(2)->{seq});
	my $pos1=0;
	my $pos2=0;
        my $sorted_seq="";
	while ($aln_pdb =~ /([^\.])/g)
        {
		if($aln_dssp[$pos1] eq '.')
		{$sorted_seq=$sorted_seq.'U';}
		else	
		{	
		    $sorted_seq=$sorted_seq.substr($sorting_seq,$pos2,1);
		    $pos2+=1;
		}
		$pos1+=1;			
        }

	return $sorted_seq;	
}

1;
