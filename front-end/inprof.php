<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Francisco M. Ortu&ntilde;o Personal Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="utf-8">
    <link rel="stylesheet" href="../bootstrap.css" media="screen">
    <link rel="stylesheet" href="../font-awesome-4.3.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="../bootswatch.min.css">
    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="html5shiv.js"></script>
      <script src="respond.min.js"></script>
    <![endif]-->
    <script type="text/javascript">

     var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-23019901-1']);
      _gaq.push(['_setDomainName', "bootswatch.com"]);
        _gaq.push(['_setAllowLinker', true]);
      _gaq.push(['_trackPageview']);

     (function() {
       var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
       ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
       var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
     })();

    </script>
	<script src="//code.jquery.com/jquery-1.10.2.js"></script>
	
  </head>
  <body>

    <div class="container">	

      <div class="page-header" id="banner">
        <div class="row">
		  <div class="col-lg-3">
			 <a href="http://www.ugr.es"><img src="../logo_ugr.gif" title="University of Granada" height=100></a>
			 <br/><br/><br/>
		  </div>
		  <div class="col-lg-6" align="right">
             <h2><strong>Francisco M. Ortu&ntilde;o Guzman</strong></h2>
			 <p class="lead" align="center"><strong><i>Personal Web Page</i></strong></p>
		  </div>
		  <div class="col-lg-3" align="right">
			 <a href="http://citic.ugr.es"><img src="../citic_logo.jpg" title="CITIC-UGR" height=100></a>

		  </div>		  
		</div>
	  </div>
	
      <!-- Navbar
      ================================================== -->
       <div class="row">		
            <div class="bs-component">
              <div class="navbar navbar-inverse">
                <div class="container-fluid">
				  <div class="navbar-header">
					<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
				  </div>									
                  <div class="navbar-collapse collapse navbar-inverse-collapse" id="bs-example-navbar">
                    <ul class="nav navbar-nav">
                      <li><a href="../index.htm">Home</a></li>
                      <li><a href="../interests.htm">Research</a></li>
					  <li><a href="../publications.htm">Publications</a></li>
					  <li class="active" class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Tools<b class="caret"></b></a>
                        <ul class="dropdown-menu">
                          <li><a href="../pacalci.htm"><strong>PAcAlCI</strong></a></li>
                          <li><a href="../mosastre.htm"><strong>MO-SAStrE</strong></a></li>
						  <li><a href="../scoring.php"><strong>MSA Advanced Scoring</strong></a></li>
						  <li><a href="./inprof.php"><strong>INPROF Web Server</strong></a></li>						  
                        </ul>
                      </li>                  
                    </ul>
                  </div><!-- /.nav-collapse -->
                </div><!-- /.container -->
              </div><!-- /.navbar -->
            </div><!-- /example -->
          </div>
		  

		  <div class="row">
            <div class="col-lg-6" align="justify">
				<div class="bs-example bs-example-type">
					<h2><strong>INPROF Web Server</strong></h2>
					<p style="font-size:16px">The INPROF (<strong>IN</strong>terrelation of <strong>PRO</strong>tein <strong>F</strong>eatures) web server provides an useful tool to retrieve several metrics and information about the relationship (similarities) among a list of proteins. 
					The web server retrieves interrelation data about a wide number of heterogeneous properties (called Categories) like sequences, domains, secondary/tertiary structures or ontological terms. 
					Also, metrics can be obtained taking into account these categories in the alignment of the protein sequences. 
					Up to 46 different metrics can be calculated from this web server to interrelate sets of proteins (See <a href="help.html">Help page</a> for details). </p>		
				</div>		  
		    </div>  
            <div class="col-lg-6" align="justify">
		        <img width="550" src="inprof.png">
				</br></br>
		    </div>
			
			<div class="col-lg-6" align="justify">
			  <div class="bs-example bs-example-type">
					<div class="well bs-component">
					  <form class="form-horizontal" action="https://iwbbio.ugr.es/database/ws/run_features.php" method="post" enctype="multipart/form-data">
						<fieldset>
						
							<legend><h3 style="font-size:18px" align="justify"> 1. Provide protein identifiers or sequences in FASTA format:</h3> </legend>	
							<textarea class="form-control" rows="4" cols="50" id="textArea"></textarea>						
							<p>OR choose your own file: <input style="font-size:14px" type="file" name="inputFile" id="inputFile"></p>
							
							<legend><h3 style="font-size:18px" align="justify"> 2. Select advanced options:</h3></legend>					
							<input class="btn btn-primary btn-sm" type="button" value="More options..." name="optButton" id="optButton">
							<div id="options" style="display: none;">

							  <div class="form-group">
								<label class="col-lg-4 control-label">Alignment Tool:</label>
								<div class="col-lg-8">
								  <select class="form-control" id="alignSelect">
									<option value="none">Not compute alignment</option>
									<option value="clustalw">ClustalW</option>
									<option value="tcoffee">T-Coffee</option>
									<option value="muscle">Muscle</option>
								  </select>
								</div>
							  </div>
							  
							  <div class="form-group">
								<label class="col-lg-4 control-label">Categories:</label>
								<div class="col-lg-8">
									  <input name="checkboxSEQ" id="checkboxSEQ" type="checkbox" value="Sequences" checked> Sequences <br/>
									  <input name="checkboxPF" id="checkboxAA" type="checkbox" value="AATypes" checked> Amino-acid Types <br/>									  
									  <input name="checkboxPF" id="checkboxPF" type="checkbox" value="Domains" checked> Domains <br/>
									  <input name="checkboxSS" id="checkboxSS" type="checkbox" value="Secondary Structure" checked> Secondary Structure <br/>
									  <input name="checkbox3D" id="checkbox3D" type="checkbox" value="Tertiary Structure" checked> Tertiary Structure <br/>
									  <input name="checkboxGO" id="checkboxGO" type="checkbox" value="Ontological Terms" checked> Ontological Terms	<br/>  						  
								</div>						  
							  </div>
																						  
							</div>
							
							<br/><br/>
							<div class="form-group">
								<div class="col-lg-4">							
									<input class="btn btn-info" style="font-size:18px" type="submit" value="Submit" name="submit" id="submit">									
								</div>
								<div class="col-lg-8">
									<h2 id="running"></h2>
								</div>														  
								<h5 id="waiting" align="center" ></h5>
							</div>



						  
						</fieldset>
					</form>
				  </div>															
			</div>		
		  </div>	
		  	
		  <div class="col-lg-6">
			  <div class="panel panel-default">
				<div class="panel-heading">
						   <h1 class="panel-title"><strong>How to use this tool</strong></h1>
				</div>
				<div class="panel-body" align="justify" style="font-size:14px">
					<p>1. Enter a list of proteins in the text area. This list can be provided by the UniProtKB <a href="http://www.uniprot.org/help/entry_name" target="new">entry name</a> or <a href="http://www.uniprot.org/help/accession_numbers" target="new">accession number</a> in different rows, for example: <br/>
							<span style="padding-left:40px;">P00509</span><br/>
							<span style="padding-left:40px;">P72173</span><br/>		
							<span style="padding-left:40px;">AAT_BACY2</span><br/>							
					or in FASTA format including protein sequences (<a href="sequences.fasta" target="new">See example</a>). A file with this information can also be uploaded.</p>
					<p>2. Configure the alignment tool and feature categories you would like to use to interrelate your proteins (See <i>"More options..."</i>):</p>
						<ul>
							<li><strong> Alignment tool:</strong> An alignment of the protein sequences in the query can be optionally performed. This alignment allows to compute additional metrics by analyzing the alignment of common features among proteins. 
							Three well-known alignment tools are now available for this option: ClustalW, T-Coffee or Muscle.</li><br/>
							<li><strong> Categories:</strong> This section allows users to configure the properties (category) they would like to take into account to interrelate proteins. Metrics calculated from these selected 
							categories will be specifically computed (the number of outputs depends on these categories). </li>
						</ul>	
					<p>3. Click <i>Submit</i> to send your query.</p>				
					<p>4. A table with values for the metrics associated to the selected categories of your proteins is provided. This table can also be downloaded in a tab-separated file.</p>
					<p>5. A detailed description of each metric is provided in the following link <a href="help.html" target="new">Feature Description</a>. </p>
					<p>6. The INPROF web server can be called from programming languages like Python, Perl or R. See a Python example script <a href="inprof_query.py" target="new">here</a>.  
					<p>7. For any additional information, questions or reporting bugs, please contact <a href="mailto:fortuno@ugr.es">fortuno@ugr.es</a>. </p>
				</div>
			  </div>	  	
		   </div>  
	    </div>	

		<br/><br/>
        <div class="row">
          <div class="col-lg-10">
            <div class="bs-component">
				<div class="alert alert-dismissible alert-danger" id="errorAlert" style="display: none;">
					<button type="button" class="close" data-dismiss="alert">&times;</button>					
				</div>

              <table class="table table-striped table-hover " id="resultTable" style="display: none;">
                <thead>
                  <tr class="active">
                    <th>#</th>
                    <th>ID</th>
                    <th>Value</th>
                    <th>Category</th>
                    <th>External Links</th>					
                  </tr>				  
                </thead>				
				<tbody id="bodyTable">						
                </tbody>
              </table>				  
			  <br/>	
			  <a id="csvLink" href="#" class="export" style="display: none;"><i>Export table data into file</i></a>
			  <br/>
			  <a id="msfAlign" href="" download="" style="display: none;"><i>Download alignment in MSF format</i></a>			  
		  			  
            </div><!-- /example -->
          </div>
        </div>

		<script>		
					$(function ()
					{   
						// Show table previously saved if required
						var param = urlParam('table');
						if (param)
						{
							//$("#bodyTable").load("https://iwbbio.ugr.es/database/ws/results/" + param + ".php?table=1");	
							$.get("https://iwbbio.ugr.es/database/ws/results/" + param + ".php?table=1", function( data ) {
								$("#bodyTable").html(data);
								$('[data-toggle="popover"]').popover({html: true});		

							});														
							$("#resultTable").show();
							$("#csvLink").show();						
						}
						
						// Show alignment link if it exists
						var linkExist = urlParam('align');
						if (linkExist)
						{
							$("#msfAlign").attr('href',"https://iwbbio.ugr.es/database/ws/results/align" + param + ".msf");
							$("#msfAlign").show();									
						}
						else
						{
							$("#msfAlign").hide();	
						}
						
					});		
		
					$("#optButton").click(function(){
					
						$("#options").toggle();
						
						var value=$("#optButton").attr("value");
						
						if (value.indexOf("Hide") >= 0){
							$("#optButton").attr('value', 'More options...');
						}
						else{
							$("#optButton").attr('value', 'Hide options...');
						}
					});
			
					// Attach a submit handler to the form
					$( "form" ).submit(function( event ) {
											
						// Stop form from submitting normally
						event.preventDefault();
	                    $("#errorAlert").hide(); 
	
						// Read file and options 
						var fileInput = document.getElementById('inputFile');
						var file = fileInput.files[0];
						var textArea = $('#textArea').val();
						var alignment = $('#alignSelect :selected').val();
						var sequences = $('#checkboxSEQ').is(":checked");
						var aatypes = $('#checkboxAA').is(":checked");						
						var domains = $('#checkboxPF').is(":checked");
						var secstruct = $('#checkboxSS').is(":checked");
						var tertiary = $('#checkbox3D').is(":checked");
						var ontology = $('#checkboxGO').is(":checked");												
						var myDate= new Date();
						var temporal = 'results' + (myDate.getMonth()+1) + (myDate.getDate()) + myDate.getHours() + myDate.getMinutes() + myDate.getSeconds() + Math.floor((Math.random() * 10000) + 1);;
												 												 
						if(!file && !textArea){
						    $("#errorAlert").html('<a href="#" class="alert-link">Oops! Protein IDs or sequences are not specified. Please, complete text area or select a file.</a>');
							$("#errorAlert").show(); 								
							$("#resultTable").hide(); 
							$("#csvLink").hide(); 	
							$("#msfAlign").hide();							
						}
						else{
									
							//Save in data object					
							var data = new FormData();
							data.append('inputFile', file);	
							data.append('textarea', textArea);	
							data.append('alignment', alignment);
							data.append('sequences', sequences);
							data.append('aatypes', aatypes);							
							data.append('domains', domains);
							data.append('secondary', secstruct);
							data.append('tertiary', tertiary);
							data.append('ontology', ontology);	
							data.append('temporal', temporal);							
							  
							$('#running').html('<i class="fa fa-spinner fa-pulse"></i>'); 
							$('#waiting').html('<i>Please wait, this procedure could take several minutes...</i><br/><i>Results will be available at <a href="https://iwbbio.ugr.es/database/ws/results/' + temporal + '.php" target="new">https://iwbbio.ugr.es/database/ws/results/' + temporal + '.php</a> </i>');
							
							// Get some values from elements on the page:
							var $form = $( this ), 
							url = $form.attr( "action" );

							// Send the data using post			  			 			  				
							$.ajax({
								type: 'POST',
								url: url, 
								data: data,
								cache: false,
								contentType: false,
								processData: false,
								timeout: 600000 //5 min timeout
							})
							.done(function(data){
								if( data.indexOf("Sorry") != -1 ){
									$("#errorAlert").html(data);
									$("#errorAlert").show(); 
									$("#resultTable").hide(); 
									$("#csvLink").hide();
									$("#msfAlign").hide();									
								}
								else{																	
									data = $.parseJSON(data);								

									var tableHTML = "";
									$.each(data, function(i, item) {
										tableHTML += '<tr class="info">';
										tableHTML += '<td width="10">' + data[i].Number + '</td>';
										tableHTML += '<td width="50"><a tabindex="0" data-toggle="popover" role="button" data-placement="top" data-container="body" data-trigger="focus" data-content="' + data[i].Description + ' <a href=\'help.html#' + data[i].ID + '\'>Learn more...</a>">' + data[i].ID + '</a></td>';
										tableHTML += '<td width="50">' + data[i].Value + '</td>';
										tableHTML += '<td width="100">' + data[i].Category + '</td>';								

										tableHTML += '<td width="100">';
										var arr = data[i].Links.split(',');
										$.each(arr, function( index, value ) {
											if(data[i].ID === "SEQ_SQ" || data[i].ID === "SEQ_MX" || data[i].ID === "SEQ_MN")
												{tableHTML += '<a href="http://www.uniprot.org/uniprot/' + value + '.fasta">' + value + '</a> ';}												
											if(data[i].ID === "SEQ_DA" || data[i].ID === "SEQ_DB" || data[i].ID === "SEQ_DT")
												{tableHTML += '<a href="http://pfam.xfam.org/family/' + value + '">' + value + '</a> ';}
											if(data[i].ID === "SEQ_DC")
												{tableHTML += '<a href="http://pfam.xfam.org/clan/' + value + '">' + value + '</a> ';}
											if(data[i].ID === "SEQ_CA" || data[i].ID === "SEQ_CB" || data[i].ID === "SEQ_CT")
												{tableHTML += '<a href="http://pfam.xfam.org/family/' + value.slice(0,-4) + '">' + value + '</a> ';}	
											if(data[i].ID === "SEQ_CK")
												{tableHTML += '<a href="http://pfam.xfam.org/clan/' + value.slice(0,-4) + '">' + value + '</a> ';}	
											if(data[i].ID === "SEQ_NS" )
												{tableHTML += '<a href="http://www.rcsb.org/pdb/explore/explore.do?structureId=' + value + '">' + value + '</a> ';}		
											if(data[i].ID === "SEQ_CS")
												{tableHTML += '<a href="http://www.rcsb.org/pdb/explore/explore.do?structureId=' + value.slice(0,-4) + '">' + value + '</a> ';}	
											if(data[i].ID === "SEQ_GO" || data[i].ID === "SEQ_MF" || data[i].ID === "SEQ_CC" || data[i].ID === "SEQ_BP")
												{tableHTML += '<a href="http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:' + value.slice(0,-2) + '">GO:' + value + '</a> ';}
											if(data[i].ID === "SEQ_CG")
												{tableHTML += '<a href="http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:' + value.slice(0,-6) + '">GO:' + value + '</a> ';}													
										});
										tableHTML += '</td>';																		
										tableHTML += '</tr>\n';										
										
									});															
									$("#bodyTable").html(tableHTML);
									$("#resultTable").show();
									$("#csvLink").show();
									if( $('#alignSelect :selected').val() !== "none")
									{
										$("#msfAlign").attr('href', 'https://iwbbio.ugr.es/database/ws/results/align' + temporal + '.msf');
										$("#msfAlign").attr('download', 'https://iwbbio.ugr.es/database/ws/results/align' + temporal + '.msf');
										$("#msfAlign").show();
									}
									else
									{					
										$("#msfAlign").hide();							
									}
									$('[data-toggle="tooltip"]').tooltip(); 
									$('[data-toggle="popover"]').popover({html: true}); 								
								}
								$('#running').html(''); 
								$('#waiting').html(''); 							
							})
							.fail(function(){			 
								// just in case posting your form failed
						        $("#errorAlert").html('<a href="#" class="alert-link">Sorry! There was a problem with the web service. Please try again in a few minutes. If the problem persists contact <a href="mailto:fortuno@ugr.es">fortuno@ugr.es</a></a>');
							    $("#errorAlert").show(); 
								$("#resultTable").hide(); 	
								$("#csvLink").hide();	
							    $("#msfAlign").hide();								
								alert( "Posting failed." );
									 
							});
													
						}						
					});
				
					// Save the search result table or the query when leaving the page.
					window.onbeforeunload = function() {
					    if( $("#waiting").html() !== "")
						{
							return "A query is still being processed. Please, check you have saved the link for the results before leaving this page.";
						}
						var table = $("#resultTable").html();
						var tableHiden = $("#resultTable").css("display");
						var linkHiden = $("#msfAlign").css("display");
						var linkHref = $("#msfAlign").attr('href');						
						sessionStorage.setItem('resultTable', table);
						sessionStorage.setItem('showTable', tableHiden);
						sessionStorage.setItem('showLink', linkHiden);	
						sessionStorage.setItem('linkHref', linkHref);							
					};

					// Replace the search result table on load.
					window.onload = function() {
						if (('sessionStorage' in window) && window['sessionStorage'] !== null) {
							if ('resultTable' in sessionStorage) {												
								$("#resultTable").html(sessionStorage.getItem('resultTable'));							
								if(sessionStorage.getItem('showTable') != 'none')
								{
								    $("#resultTable").show();
									$("#csvLink").show();									
								}	
								if(sessionStorage.getItem('showLink') != 'none')
								{  
									$("#msfAlign").attr('href', sessionStorage.getItem('linkHref'));								
									$("#msfAlign").show();	
								}
							}	
						}
						$('[data-toggle="tooltip"]').tooltip(); 
						$('[data-toggle="popover"]').popover({html: true}); 	
					};

					// Export table to file
					function exportTableToCSV($table, filename) {

						var $rows = $table.find('tr:has(td),tr:has(th)'),

							tmpColDelim = String.fromCharCode(11), // vertical tab character
							tmpRowDelim = String.fromCharCode(0), // null character

							colDelim = '"\t"',
							rowDelim = '"\r\n"',

							// Grab text from table into CSV formatted string
							csv = '"' + $rows.map(function (i, row) {
								var $row = $(row),
									$cols = $row.find('td,th');

								return $cols.map(function (j, col) {
									var $col = $(col),
										text = $col.text();

									return text.replace(/"/g, '""'); // escape double quotes

								}).get().join(tmpColDelim);

							}).get().join(tmpRowDelim)
								.split(tmpRowDelim).join(rowDelim)
								.split(tmpColDelim).join(colDelim) + '"',

							// Data URI
							csvData = 'data:application/csv;charset=utf-8,' + encodeURIComponent(csv);

						$(this)
							.attr({
							'download': filename,
								'href': csvData,
								'target': '_blank'
						});
					}

					// Click event in hyperlink for exportation
					$(".export").on('click', function (event) {
						// CSV
						exportTableToCSV.apply(this, [$('#resultTable'), 'result.txt']);
						
						// IF CSV, don't do event.preventDefault() or return false
						// We actually need this to be a typical hyperlink
					});

					// Function to retrieve parameters from URL
					function urlParam(name){
						var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
						if (results==null){
						   return null;
						}
						else{
						   return results[1] || 0;
						}
					}					
					
																	
		</script>			
		
	  <br/><br/>
      <footer>
        <div class="row">
          <div class="col-lg-10">
            
            <ul class="list-unstyled">
              <li class="pull-right"><a href="#top">Back to top</a></li>
            </ul>
            <p style="font-size:8px">Template licensed under the <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License v2.0</a>.</p>
            <p style="font-size:8px">Based on <a href="http://getbootstrap.com">Bootstrap</a>. Icons from <a href="http://fortawesome.github.io/Font-Awesome/">Font Awesome</a>. Web fonts from <a href="http://www.google.com/webfonts">Google</a>. Favicon by <a href="https://twitter.com/geraldhiller">Gerald Hiller</a>.</p>

          </div>
        </div>    
      </footer>
    
    </div>


    <script src="../jquery.min.js"></script>
    <script src="../bootstrap.min.js"></script>
    <script src="../bootswatch.js"></script>
	<!--<script src="../custom.js"></script>-->
  </body>
</html>