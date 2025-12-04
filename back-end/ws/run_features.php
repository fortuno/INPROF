<?php 
     header('Access-Control-Allow-Origin: *');				
     require_once ('/usr/share/php/nusoap/nusoap.php');	
     include 'create_html.php';
     ignore_user_abort(true);				
     putenv("TEMP=/tmp");

     $textarea = $_POST["textarea"];
     $alignTool = $_POST["alignment"];
     $seqFeat = $_POST["sequences"];
     $aaFeat = $_POST["aatypes"];
     $domFeat = $_POST["domains"];
     $secFeat = $_POST["secondary"];
     $pdbFeat = $_POST["tertiary"];
     $ontoFeat = $_POST["ontology"];
     $temporal = $_POST["temporal"];
     
     // Writing temporary html file for results
     $tempfile = "results/".$temporal.".php";
     $htmlfile = fopen($tempfile,"w");
     fwrite($htmlfile,"<?php
			echo '<html>Please wait, this procedure could take several minutes...<br/>Results will be reported here when the procedure finished and they will be maintained in server during 48h.</html>'
			?>");
     fclose($htmlfile);

     if(empty($textarea))
     {				
     	// Upload file
        $dataOK = 1;
     	$target_dir = "uploads/";
     	$target_file = $target_dir.time().basename($_FILES["inputFile"]["name"]);
     	$FileType = pathinfo($target_file,PATHINFO_EXTENSION);				
       
     	if (!move_uploaded_file($_FILES["inputFile"]["tmp_name"], $target_file)) {
	 	echo "Sorry, there was an error uploading your file.";
              $htmlfile = fopen($tempfile,"w");
              fwrite($htmlfile,"<?php
		    echo '<html>Sorry, there was an error uploading your file.</html>'
		?>");
              fclose($htmlfile);
	 	$dataOK=0;
     	}

	// Convert file to UNIX
        $file = $target_file;
	$result = shell_exec("dos2unix $file");

	// Running Perl script with the uploaded file       
        if($dataOK){
	   $execute = "perl protein_features.pl -file='$file' -tool='$alignTool' -sequences='$seqFeat' -aatypes='$aaFeat' -domains='$domFeat' -secondary='$secFeat' -tertiary='$pdbFeat' -go='$ontoFeat' -temp='$temporal'";
	   $result = shell_exec($execute);
	}
     }
     else{
	// Running Perl script with the text in textarea
	$execute = "perl protein_features.pl -text='$textarea' -tool='$alignTool' -sequences='$seqFeat' -aatypes='$aaFeat' -domains='$domFeat' -secondary='$secFeat' -tertiary='$pdbFeat' -go='$ontoFeat' -temp='$temporal'";
	$result = shell_exec($execute);
        $cmdfile = fopen("results/command".$temporal.".txt","w");
        fwrite($cmdfile, $execute."\n".$result."\nEND\n");
  	fclose($cmdfile);

     }

     // Write error in html output if produced
     if (strpos($result,'Sorry') !== false) {
       	$htmlfile = fopen($tempfile,"w");
              fwrite($htmlfile,"<?php
		    echo '<html> $result </html>';
		?>");
              fclose($htmlfile);
     }
     else {
         // Save temporary website with results
         $tableHTML = create_html($result, $tempfile, $temporal);
     }

     $logfile = fopen("results/salida".$temporal.".txt","w");
     fwrite($logfile, $result);
     fclose($logfile);

     echo $result;

?> 					
