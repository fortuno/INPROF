use strict;
use warnings;

sub shared_features {

   my @feats = @{$_[0]};
   my $numSeq = $_[1]; 

   my %counts;
   $counts{$_}++ for @feats; 

   my @repetitions = values %counts;
   my @features = keys %counts;

   # Count shared features taken two by two
   my $shared=0;
   my $f1; my $f2;
   my $rep1; my $rep2;
   my @outputF;
   for (my $i=0; $i <= $#repetitions; $i++)
   {
      my $rep = $repetitions[$i];
      my $feature = $features[$i];

      # Calculate number of combinations
      if($rep>1)
      {        	
	push @outputF, ($feature." (".$rep.")");

	$f1=1;
        $rep1=$rep;
	$f1 *= $rep1-- while $rep1 > 0;
	      
	$f2=1;
	$rep2 = $rep-2;
	$f2 *= $rep2-- while $rep2 > 0;

	$shared += $f1/(2*$f2);
      }
   }

   # Count total combinations taken two by two
   $f1=1; $f2=1;
   $rep1 = $numSeq;
   $f1 *= $rep1-- while $rep1 > 0;
   $rep2 = $numSeq - 2;
   $f2 *= $rep2-- while $rep2 > 0;
   my $total = $f1/(2*$f2);

   # Calculate shared features per sequence
   $shared = $shared/$total;

   my $outfeat = join ",", @outputF;

   return ($shared, $outfeat);
}
1;
