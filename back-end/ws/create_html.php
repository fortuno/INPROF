<?php 


function create_html($result, $file, $temporal) {
    
     $data = json_decode($result);
     $isAlign = file_exists('./results/align'.$temporal.'.msf');

     $tableHTML = '<?php
     			header(\'Access-Control-Allow-Origin: *\');	
                   if($_GET["table"] === "1"){
';

     $tableHTML .= 'echo \'';
     foreach($data as $doc){
	$tableHTML .= '<tr class="info">';
	$tableHTML .= '<td width="10">'.$doc->Number.'</td>';
	$tableHTML .= '<td width="50"><a tabindex="0" data-toggle="popover" role="button" data-placement="top" data-container="body" data-trigger="focus" data-content="'.$doc->Description.' <a href=\\\'help.html#'.$doc->ID.'\\\'>Learn more...</a>">'.$doc->ID.'</a></td>';
	$tableHTML .= '<td width="50">'.$doc->Value.'</td>';
	$tableHTML .= '<td width="100">'.$doc->Category.'</td>';		

	$tableHTML .= '<td width="100">';
	$arr = explode(",", $doc->Links);

	foreach($arr as $value){
 	   if($doc->ID == "SEQ_SQ" || $doc->ID == "SEQ_MX" || $doc->ID == "SEQ_MN")
		{$tableHTML .= '<a href="http://www.uniprot.org/uniprot/'.$value.'.fasta">'.$value.'</a> ';}
 	   if($doc->ID == "SEQ_DA" || $doc->ID == "SEQ_DB" || $doc->ID == "SEQ_DT")
		{$tableHTML .= '<a href="http://pfam.xfam.org/family/'.$value.'">'.$value.'</a> ';}
	   if($doc->ID == "SEQ_DC")
		{$tableHTML .= '<a href="http://pfam.xfam.org/clan/'.$value.'">'.$value.'</a> ';}
	   if($doc->ID == "SEQ_CA" || $doc->ID == "SEQ_CB" || $doc->ID == "SEQ_CT")
		{$tableHTML .= '<a href="http://pfam.xfam.org/family/'.substr($value,0,-4).'">'.$value.'</a> ';}	
           if($doc->ID == "SEQ_CK")
		{$tableHTML .= '<a href="http://pfam.xfam.org/clan/'.substr($value,0,-4).'">'.$value.'</a> ';}	
	   if($doc->ID == "SEQ_NS" )
		{$tableHTML .= '<a href="http://www.rcsb.org/pdb/explore/explore.do?structureId='.$value.'">'.$value.'</a> ';}		
	   if($doc->ID == "SEQ_CS")
		{$tableHTML .= '<a href="http://www.rcsb.org/pdb/explore/explore.do?structureId='.substr($value,0,-4).'">'.$value.'</a> ';}	
	   if($doc->ID == "SEQ_GO" || $doc->ID == "SEQ_MF" || $doc->ID == "SEQ_CC" || $doc->ID == "SEQ_BP")
		{$tableHTML .= '<a href="http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:'.substr($value,0,-2).'">GO:'.$value.'</a> ';}
	   if($doc->ID == "SEQ_CG")
		{$tableHTML .= '<a href="http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:'.substr($value,0,-6).'">GO:'.$value.'</a> ';}	       
        }

	$tableHTML .= '</td>';																		
	$tableHTML .= '</tr>';
                             
     }
     $tableHTML .= '\';
     }
     else{
 	echo \'<html><head><meta http-equiv="Refresh" content="0;url=http://www.ugr.es/~fortuno/inprof/inprof.php?table='.$temporal.'&align='.$isAlign.'">
                        </head></html>\';
     } 
     ?>';

     $myfile = fopen($file, "w") or die("Unable to open file!");
     fwrite($myfile, $tableHTML);
     fclose($myfile);

     return $tableHTML;

}



?> 
