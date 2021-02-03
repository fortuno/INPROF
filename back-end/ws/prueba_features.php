<?php 
     header('Access-Control-Allow-Origin: *');				
     require_once ('/usr/share/php/nusoap/nusoap.php');	
     include 'create_html.php';
     ignore_user_abort(true);				
     putenv("TEMP=/tmp");

     $temporal = "pruebatemporal";
     
     // Writing temporary html file for results
     $tempfile = "results/".$temporal.".php";
     $htmlfile = fopen($tempfile,"w");
     fwrite($htmlfile,"<?php
			echo '<html>Please wait, this procedure could take several minutes...<br/>Results will be reported here when the procedure finished and they will be maintained in server during 48h.</html>'
			?>");
     fclose($htmlfile);

     echo "Ejecutando";
     $execute = "perl protein_features.pl -file='./uploads/sequences.txt'";
     $result = shell_exec($execute);     

     echo "RESULT:".$result;

?> 					
