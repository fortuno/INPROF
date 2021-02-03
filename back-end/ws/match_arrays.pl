use strict;
use warnings;

sub match_arrays {

   # Read sequences and characters to match
   my @seq1 = @{$_[0]}; 
   my @seq2 = @{$_[1]}; 

   my $index=0;
   my $matches=0;
   while($index <= $#seq1)
   {
       if($seq1[$index] =~ /[^\.|\:|\-]/ & $seq2[$index] =~ /[^\.|\:|\-]/)
		{$matches += 1 if $seq1[$index] eq $seq2[$index];}
	
       $index++;
   } 

   return $matches;
}
1;
