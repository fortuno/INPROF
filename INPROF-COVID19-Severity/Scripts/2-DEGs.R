require(KnowSeq)

computeGenes_OVControl <- function(originalGeneMatrix,original.labels,category,lfc = 1, pvalue = 0.001) {
  #Get index where Control patients are placed
  control.index <- which(original.labels=='Control')
  #Get index where category patients are placed
  category.index <- which(original.labels==category)
  
  #Initialize an empty list where each element of the list represents one category patient and will hold each patient DEGs
  empty_list <- vector(mode = "list", length = length(category.index))
  all_index <- c(1:length(category.index))
  
  for (i in all_index){
    #pick one of the category patient
    print(i)
    chosen <- c(control.index, category.index[i])
    labels.categoryvsAll_n <- factor(original.labels[chosen])
    expressionMatrix.categoryvsAll_n <- originalGeneMatrix[,chosen]
    
    print(length(levels(labels.categoryvsAll_n)) == 2)
    #Get Genes
    DEGsInfo.categoryvsAll_n <- DEGsExtraction(expressionMatrix.categoryvsAll_n, labels.categoryvsAll_n, lfc = lfc, pvalue = pvalue)
    
    #Get genes matrix
    DEGs_Matrix.categoryvsAll_n <- DEGsInfo.categoryvsAll_n$DEG_Results$DEGs_Matrix
    DEGs <- row.names(DEGs_Matrix.categoryvsAll_n)
    empty_list[[i]]<-DEGsInfo.categoryvsAll_n$DEG_Results$DEGs_Table #DEGs
  }
  return(empty_list)
}

# Load joined matrix from previous script
load("../Data/joined_datasets.Rdata")

#Get Inpatients DEGs with LFC=1.6 and select top 40
imvsControl <- computeGenes_OVControl(expressionMatrix,labels,'Inpatient',lfc=1.5) #1.6
imvsControl <- lapply(imvsControl, head, 170)

#Get Outpatients DEGs with LFC=0.95 and select top 31
outvsControl <- computeGenes_OVControl(expressionMatrix,labels,'Outpatient',lfc=1.5) #0.95
outvsControl <- lapply(outvsControl, head, 170)

#Get UCI DEGs with LFC=1.1 and select top 45
UCIvsControl <- computeGenes_OVControl(expressionMatrix,labels,'ICU',lfc=1.5) # 1.1
UCIvsControl <- lapply(UCIvsControl, head, 170)

#Get n genes per group
Inpatient.DEGs <- lapply(imvsControl,rownames)
UCI.DEGs <- lapply(UCIvsControl,rownames) 
Outpatient.DEGs <- lapply(outvsControl,rownames) 
