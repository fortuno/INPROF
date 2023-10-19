require(httr)
require(jsonlite)
require(stringr)
require(stringi)

#Function that queries a list of proteins to INPROF
getInprof <- function(proteines, temporal, alignment='none',sequences='true',
                      aatypes='true',domains='true',secondary='true',
                      tertiary='true',ontology='true'){
  
  res <- POST("http://iwbbio.ugr.es/database/ws/run_features.php", 
              body = list(textarea=proteines,
                          alignment=alignment,sequences=sequences,aatypes=aatypes,
                          domains=domains,secondary=secondary,tertiary=tertiary,
                          ontology=ontology,temporal=temporal))
  
  response <- content(res, "text", encoding = "utf-8")
  prots.df <- fromJSON(response)
  return(prots.df)
}

#Get UCI INPROF features with muscle as alignment tool
count <- 0
for (p in UCI.Proteins){
  count<-count+1
  id <- paste("UCI_",count, sep = "")
  print(id)
  if(count==1){
    inprof.response<-getInprof(paste(p, collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    UCI.characteristics.alignment <- patient
  }
  else{
    inprof.response<-getInprof(paste(p, collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    UCI.characteristics.alignment<-rbind(UCI.characteristics.alignment, patient)
  }
}


#Get Inpatient INPROF features with muscle as alignment tool
count <- 0
for (p in Inpatient.Proteins){
  count<-count+1
  id <- paste("IN_",count, sep = "")
  print(id)
  if(count==1){
    inprof.response<-getInprof(paste(p, collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    Inpatient.characteristics.alignment <- patient
  }
  else{
    inprof.response<-getInprof(paste(p, collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    Inpatient.characteristics.alignment<-rbind(Inpatient.characteristics.alignment, patient)
  }
}

#Get Outpatient INPROF features with muscle as alignment tool
count <- 0
for (p in Outpatient.Proteins){
  count<-count+1
  id <- paste("OUT_",count, sep = "")
  print(id)
  if(count==1){
    inprof.response<-getInprof(paste(unique(p), collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    Outpatient.characteristics.alignment <- patient
  }
  else{
    inprof.response<-getInprof(paste(unique(p), collapse = "\n"),alignment = 'muscle',temporal = id)
    patient <- inprof.response$Value
    Outpatient.characteristics.alignment<-rbind(Outpatient.characteristics.alignment, patient)
  }
}


#Prepare data frame
#Change every number from string to numeric
UCI.characteristics.numeric.alignment <- as.data.frame(apply(UCI.characteristics.alignment,2,as.numeric))
Outpatient.characteristics.numeric.alignment <- as.data.frame(apply(Outpatient.characteristics.alignment,2,as.numeric))     
Inpatient.characteristics.numeric.alignment <- as.data.frame(apply(Inpatient.characteristics.alignment,2,as.numeric))

#Build label vectors
UCI.data.alignment <- cbind(UCI.characteristics.numeric.alignment,rep("UCI",dim(UCI.characteristics.numeric.alignment)[1]))
Outpatient.data.alignment <- cbind(Outpatient.characteristics.numeric.alignment,rep("OUT",dim(Outpatient.characteristics.numeric.alignment)[1]))
Inpatient.data.alignment <- cbind(Inpatient.characteristics.numeric.alignment,rep("IN",dim(Inpatient.characteristics.numeric.alignment)[1]))
#Remove row names
row.names(UCI.data.alignment)<-NULL
row.names(Outpatient.data.alignment)<-NULL
row.names(Inpatient.data.alignment)<-NULL

#Create variables names vector
characteristic.names.alignment<-c('SEQ_SQ', 'SEQ_LG', 'SEQ_MX', 'SEQ_MN', 'SEQ_VA', 'SEQ_PL', 
                                  'SEQ_NP', 'SEQ_BS', 'SEQ_AR', 'SEQ_AC', 'SEQ_PA', 'SEQ_PB',
                                  'SEQ_PT', 'SEQ_PC', 'SEQ_DA', 'SEQ_DB', 'SEQ_DT', 'SEQ_DC',
                                  'SEQ_CA', 'SEQ_CB', 'SEQ_CT', 'SEQ_CK', 'SEQ_HX', 'SEQ_TD',
                                  'SEQ_TN', 'SEQ_SU', 'SEQ_NS', 'SEQ_PS', 'SEQ_CS', 'SEQ_NC',
                                  'SEQ_GO', 'SEQ_MF', 'SEQ_CC', 'SEQ_BP', 'SEQ_CG', 'MSA_ID',
                                  'MSA_GP', 'MSA_TC', 'MSA_PL', 'MSA_NP', 'MSA_BS', 'MSA_AR',
                                  'MSA_AC', 'MSA_PT', 'MSA_PB', 'MSA_PC', 'MSA_HX',
                                  'MSA_TD', 'MSA_TN', 'MSA_SU', 'MSA_SS', 'MSA_3D', 'MSA_SK',
                                  'label')

colnames(UCI.data.alignment)<-characteristic.names.alignment
colnames(Outpatient.data.alignment)<-characteristic.names.alignment
colnames(Inpatient.data.alignment)<-characteristic.names.alignment

#Join all data and remove variables which are all zeros 
data.alignment <- rbind(UCI.data.alignment,Outpatient.data.alignment,Inpatient.data.alignment)
zeros.alignment <- which(apply(data.alignment[,-54], 2, sum)==0)
data.alignment.final <- as.data.frame(data.alignment[,-c(1, zeros.alignment)])
