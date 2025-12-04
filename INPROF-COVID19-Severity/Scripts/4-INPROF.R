require(httr)
require(httr2)
require(jsonlite)
require(stringr)
require(stringi)

#Function that queries a list of proteins to INPROF
getInprof <- function(proteins, temporal, alignment = 'none', sequences = 'true', 
                      aatypes = 'true', domains = 'true', secondary = 'true', 
                      tertiary = 'true', ontology = 'true') {
  
  resp <- request("http://iwbbio.ugr.es/database/ws/run_features.php") |>
    req_body_form(textarea = proteins,
                  alignment = alignment,
                  sequences = sequences,
                  aatypes = aatypes,
                  domains = domains,
                  secondary = secondary,
                  tertiary = tertiary,
                  ontology = ontology,
                  temporal = temporal) |> 
    req_options(
      timeout_ms = 333333000,       
      low_speed_limit = 0,    #Set to 0 to disable
      low_speed_time  = 3600  #seconds
    ) |>
    req_perform() |>
    resp_body_string()
  
  prots.df <- fromJSON(resp)
  
  return(prots.df)
}

getMultipleQuery <- function(proteins, alignment="muscle", prefix){
  count <- 0
  for (p in proteins){
    count<-count+1
    id <- paste(prefix, "_",count, sep = "")
    print(id)
    
    # Make query
    tryCatch({
      inprof.response<-getInprof(paste(p, collapse = "\n"), 
                                 alignment = alignment,temporal = id)
      # For debug purposes: save(list = c("inprof.response"), file = paste0("../Features/", id ,".Rdata"))
      patient <- inprof.response$Value
    }, error = function(e) {
      cat("Error for sample:", id, "\n", e$message, "\n")
      patient <- rep("NA", 54)
    })  
    
    # Join queries
    if(count==1){
      characteristics.alignment <- patient
      initial_row <- id
    }
    else{
      characteristics.alignment<-rbind(characteristics.alignment, patient)
      if(count==2){
        rownames(characteristics.alignment)[1] <- initial_row
        colnames(characteristics.alignment) <- inprof.response$ID
      }
      rownames(characteristics.alignment)[count] <- id
    }
  }
  
  # Convert to numeric
  characteristics.alignment.DF <- as.data.frame(apply(characteristics.alignment,2,as.numeric))
  rownames(characteristics.alignment.DF) <- rownames(characteristics.alignment)
  
  return(characteristics.alignment.DF)
}

# Save for following scripts
load(file = "../Data/canonical_proteins.Rdata")

# Get UCI INPROF features with muscle as alignment tool
UCI.characteristics.alignment <- getMultipleQuery(UCI.Proteins, 
                                                  alignment="muscle", 
                                                  prefix="UCI")

# Get Inpatient INPROF features with muscle as alignment tool
Inpatient.characteristics.alignment <- getMultipleQuery(Inpatient.Proteins, 
                                                        alignment="muscle",
                                                        prefix="IN")

# Get Outpatient INPROF features with muscle as alignment tool
Outpatient.characteristics.alignment <- getMultipleQuery(Outpatient.Proteins, 
                                                         alignment="muscle",
                                                         prefix="OUT")
# Build label vectors
UCI.data.alignment <- cbind(UCI.characteristics.alignment,rep("UCI",dim(UCI.characteristics.alignment)[1]))
Outpatient.data.alignment <- cbind(Outpatient.characteristics.alignment,rep("OUT",dim(Outpatient.characteristics.alignment)[1]))
Inpatient.data.alignment <- cbind(Inpatient.characteristics.alignment,rep("IN",dim(Inpatient.characteristics.alignment)[1]))

# Remove row names
row.names(UCI.data.alignment)<-NULL
row.names(Outpatient.data.alignment)<-NULL
row.names(Inpatient.data.alignment)<-NULL

# Rename last column
colnames(UCI.data.alignment)[length(UCI.data.alignment)]<-"label"
colnames(Outpatient.data.alignment)[length(Outpatient.data.alignment)]<-"label"
colnames(Inpatient.data.alignment)[length(Inpatient.data.alignment)]<-"label"

#Join all data and remove variables which are all zeros 
data.alignment <- rbind(UCI.data.alignment,Outpatient.data.alignment,Inpatient.data.alignment)
zeros.alignment <- which(apply(data.alignment[,-55], 2, sum)==0)
data.alignment.final <- as.data.frame(data.alignment[,-zeros.alignment])

# Save results with and without filter
save(list = c("data.alignment"), file = "../Data/inprof_features.Rdata")
save(list = c("data.alignment.final"), file = "../Data/inprof_features_final.Rdata")
