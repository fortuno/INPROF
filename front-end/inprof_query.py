import requests
import json
 
params = {
            "textarea": "P00509\nP72173", 	# One protein ID per line
            "alignment": "none", 			# Select the aligment tool used
            "sequences": "true", 			# Sequence category: true/false
            "aatypes": "true",				# Amino-acids category: true/false
            "domains": "true",				# Domains category: true/false
            "secondary": "true",			# 2nd Structure category: true/false
            "tertiary": "true",				# 3rd Structure category: true/false
            "ontology": "true"				# Ontology category: true/false
}

# Run PHP back-end web server
resp = requests.post("http://iwbbio.ugr.es/database/ws/run_features.php", data = params)

# Get JSON output in dictionary
results = json.loads(resp.text)