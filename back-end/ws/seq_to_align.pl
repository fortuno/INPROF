use strict;
use warnings;

sub seq_to_align {

   # Read arguments
   my $seq = $_[0];
   my $seqAlign = $_[1];

   if(ref($seq) eq "ARRAY")
   {
       my @array = @{$seq};	
       
       # Convert array according to the alignment
       my $pos = 0;
       my @result = split("",$seqAlign);
       while ($seqAlign =~ /([^\.|\-|\:])/g)
       {	     
          my $alpos = $-[0];
          $result[$alpos] = $array[$pos];	
          $pos++;		
        }

	return \@result;
   }
   else
   { 
	# Convert sequence according to the alignment
        my $pos = 0;
	my $result = $seqAlign;
	while ($seqAlign =~ /([^\.|\-|\:])/g)
        {	     
            my $alpos = $-[0];
	    my $value = substr($seq,$pos,1);
	    substr($result,$alpos,1,$value);	
	    $pos++;		
        }
        
	return $result;

   }
   

}
1;
