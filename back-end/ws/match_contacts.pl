use strict;
use warnings;

sub match_contacts {

   # Read first aligned sequence and its corresponding contacts
   my $seq1 = $_[0];  
   my $con1 = $_[2];
   my $num1 = ($con1 =~ tr/\n//);
   $con1 = $con1."\n";

   # Read second aligned sequence and its corresponding contacts
   my $seq2 = $_[1];
   my $con2 = $_[3];
   my $num2 = ($con2 =~ tr/\n//);
   $con2 = $con2."\n";

   # Recalcule contact positions in the first aligned sequence
   $con1 =~ /^(\w+) /;
   my $seqname = $1;	
   my $index = 1;
   while ($seq1 =~ /[A-Za-z]/g) {
      my $pos = $+[0];   
      $con1 =~ s/$seqname $index /$pos /g;
      $con1 =~ s/ $index\n/\t$pos\n/g;
      $index++;
   }

   # Recalcule contact positions in the second aligned sequence
   $con2 =~ /^(\w+) /;
   $seqname = $1;	
   $index = 1;
   while ($seq2 =~ /[A-Za-z]/g) {
      my $pos = $+[0];   
      $con2 =~ s/$seqname $index /$pos /g;
      $con2 =~ s/ $index\n/\t$pos\n/g;
      $index++;
   }

   # Count repetitions in contacts of both sequences
   my @contacts = split ("\n", $con1.$con2);
   my %counts = ();
   $counts{$_}++ for @contacts;
   my @repetitions = values %counts;

   # Calculate matched contacts and total of possible matches
   my $matches = 0;
   $matches += ($_ == 2) for (@repetitions);
   my $total_matches = $num1 >= $num2 ? $num1 : $num2;
 
   return ($matches, $total_matches);
}
1;
