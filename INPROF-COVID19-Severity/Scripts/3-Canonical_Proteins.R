require(httr)
require(jsonlite)
require(stringr)

#Build a function that gets canonic proteins from a list of genes via UniProt specifying the ID origin
getProteins <- function(genes, from='ENSEMBL_ID', to='SWISSPROT'){
  res = GET("https://www.uniprot.org/uploadlists/", 
            query = list(from=from,to=to, format='tab',query = genes,columns = 'entry name'))
  response <- content(res, "text", encoding = "utf-8")
  first_split <- unlist(strsplit(response,split = "\n"))
  genes<-c()
  proteines<-c()
  for (i in c(2:length(first_split))) {
    prot_gene <- unlist(strsplit(first_split[i],split = "\t"))
    genes <- c(genes,prot_gene[2])
    proteines <- c(proteines,prot_gene[1])
  }
  return(data.frame(EnsemblGenes = genes, proteine = proteines))
}

#Function that gets canonic proteins from genes vector without assuming what is the origin of the IDs.
getCanonicProtein <- function(genesVector){
  not.found.genes<-c()
  proteines <- c()
  for (gen in genesVector){
    biomuta <- getProteins(gen, from='BIOMUTA_ID', to='ACC')
    if(!is.na(biomuta$proteine[1])){
      proteines<-c(proteines,biomuta$proteine[1])
    }
    else{
      ensemblID<-getGenesAnnotation(c(gen),filter="external_gene_name")
      continue = TRUE
      for (names in ensemblID$ensembl_gene_id){
        if(continue){
          ensembl<-getProteins(names,to='ACC')
          if(!is.na(ensembl$proteine[1])){
            proteines<-c(proteines,ensembl$proteine[1])
            continue = FALSE
          }
        }
      }
      if (continue){
        genecards <- getProteins(gen, from='GENECARDS_ID', to='ACC')
        if(!is.na(genecards$proteine[1])){
          proteines<-c(proteines,genecards$proteine[1])
        }
        else{
          not.found.genes<-c(not.found.genes,gen)
        }
      }
    }
  }
  cat("//////////////////////////// \n")
  cat("Not found genes:",not.found.genes,"\n")
  cat("//////////////////////////////// \n")
  return(proteines)
}

##Get canonic proteins for each patient
UCI.Proteins <- lapply(UCI.DEGs,getCanonicProtein)
Outpatient.Proteins<-lapply(Outpatient.DEGs,getCanonicProtein)
Inpatient.Proteins <- lapply(Inpatient.DEGs,getCanonicProtein)

#Get all proteins for each patient group
UCI.all.prot <- unique(unlist(UCI.Proteins))
Out.all.prot <- unique(unlist(Outpatient.Proteins))
Inp.all.prot <- unique(unlist(Inpatient.Proteins))

all.proteines <- unique(c(UCI.all.prot,Out.all.prot,Inp.all.prot))


