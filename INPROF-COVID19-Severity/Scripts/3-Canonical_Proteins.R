require(httr)
require(stringr)

# Functions provided by Uniprot Mapping ID 

isJobReady <- function(jobId) {
  pollingInterval = 5
  nTries = 20
  for (i in 1:nTries) {
    url <- paste("https://rest.uniprot.org/idmapping/status/", jobId, sep = "")
    r <- GET(url = url, accept_json())
    status <- content(r, as = "parsed")
    if (!is.null(status[["results"]]) || !is.null(status[["failedIds"]])) {
      return(TRUE)
    }
    if (!is.null(status[["messages"]])) {
      print(status[["messages"]])
      return (FALSE)
    }
    Sys.sleep(pollingInterval)
  }
  return(FALSE)
}

getResultsURL <- function(redirectURL) {
  if (grepl("/idmapping/results/", redirectURL, fixed = TRUE)) {
    url <- gsub("/idmapping/results/", "/idmapping/stream/", redirectURL)
  } else {
    url <- gsub("/results/", "/results/stream/", redirectURL)
  }
}

getCanonicalProtein <- function(geneList){
  chunks <- ceiling(length(geneList)/1000)
  chunkedList <- split(geneList, 1:chunks)
  fullTable <- data.frame()
  for (id in 1:length(chunkedList))
  {
      cat("Querying Uniprot with chunk", id, "...\n")
      chGeneList <- chunkedList[[id]]
      files = list(
        ids = paste(chGeneList,collapse=","),
        from = "Gene_Name",
        to = "UniProtKB",
        taxId = "9606"
      )
      r <- POST(url = "https://rest.uniprot.org/idmapping/run", body = files, encode = "multipart", accept_json())
      submission <- content(r, as = "parsed")
      
      if (isJobReady(submission[["jobId"]])) {
        url <- paste("https://rest.uniprot.org/idmapping/details/", submission[["jobId"]], sep = "")
        r <- GET(url = url, accept_json())
        details <- content(r, as = "parsed")
        url <- getResultsURL(details[["redirectURL"]])
        # Using TSV format see: https://www.uniprot.org/help/api_queries#what-formats-are-available
        url <- paste(url, "?format=tsv", sep = "")
        r <- GET(url = url, accept_json())
        resultsTable <- read.csv(text = content(r), sep = "\t", header=TRUE)
        resultsTable <- resultsTable[resultsTable$Reviewed=="reviewed",]
        # Join queries
        if(id==1){
          fullTable <- resultsTable
        }
        else{
          fullTable <- rbind(fullTable, resultsTable)
        }
      }
  }
  return(fullTable)
}

convertToProteins <- function(GeneList, Proteins){
  ProteinList <- Proteins[Proteins$From %in% GeneList,]
  # Keep only main proteins if several per gene
  ProteinList$First.Gene <- sapply(str_split(ProteinList$Gene.Names, " "), "[[", 1)
  ProteinList <- ProteinList[ProteinList$From == ProteinList$First.Gene,] 
  UniprotIDs <- ProteinList$Entry
  return(UniprotIDs)
}

# Join all gene names to make only one query
UCI.GeneList <- unique(unlist(UCI.DEGs))
Outpatient.GeneList <- unique(unlist(Outpatient.DEGs))
Inpatient.GeneList <- unique(unlist(Inpatient.DEGs))
Total.GeneList <- unique(c(UCI.GeneList, Outpatient.GeneList, Inpatient.GeneList))
Total.Proteins <- unique(getCanonicalProtein(Total.GeneList))

# Convert gene names for all conditions. Two conditions could occur:
# 1) Some genes have associated several reviewed proteins (keep only main one)
# 2) Some genes are still not validated so no protein is found
UCI.Proteins <- lapply(UCI.DEGs, convertToProteins, Total.Proteins)
Outpatient.Proteins <- lapply(Outpatient.DEGs, convertToProteins, Total.Proteins)
Inpatient.Proteins <- lapply(Inpatient.DEGs, convertToProteins, Total.Proteins)

# Save for following scripts
save(list = c("UCI.Proteins", "Outpatient.Proteins", "Inpatient.Proteins"), file = "../Data/canonical_proteins.Rdata")
