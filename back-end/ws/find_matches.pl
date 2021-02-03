use strict;
use warnings;

sub find_matches {

   # Read sequences and characters to match
   my $seq1 = $_[0]; 
   my $seq2 = $_[1]; 
   my @chars_to_match = @{$_[2]};

   # Join characters to match
   my $characters;
   if($#chars_to_match > 0)
   	{$characters = join('|',@chars_to_match);}
   else
        {$characters = $chars_to_match[0];}

   # Mark with X positions of the selected characters
   $seq1 =~ s/$characters/X/g;
   $seq2 =~ s/$characters/X/g;

   # Differenciate the remaining characters
   $seq1 =~ s/[^X]/-/g; 
   $seq2 =~ s/[^X]/:/g; 

   # Count matches of Xs
   my $matches = ((lc $seq1 ^ lc $seq2) =~ tr/\0//); # Matches in non-polar AAs

   return $matches;
}
1;
