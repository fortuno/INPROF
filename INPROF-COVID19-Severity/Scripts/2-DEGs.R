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
    #pick one of the category patience
    print(i)
    chosen <- c(control.index, category.index[i])
    labels.categoryvsAll_n <- original.labels[chosen]
    expressionMatrix.categoryvsAll_n <- originalGeneMatrix[,chosen]
    
    print(length(levels(labels.categoryvsAll_n)) == 2)
    #Get Genes
    DEGsInfo.categoryvsAll_n <- DEGsExtraction(expressionMatrix.categoryvsAll_n, labels.categoryvsAll_n, lfc = lfc, pvalue = pvalue)
    
    #Get genes matrix
    DEGs_Matrix.categoryvsAll_n <- DEGsInfo.categoryvsAll_n$DEG_Results$DEGs_Matrix
    DEGs <- row.names(DEGs_Matrix.categoryvsAll_n)
    empty_list[[i]]<-DEGs
  }
  return(empty_list)
}

#Get DEGs with LFC = 1
outvsControl <- computeGenes_OVControl(expressionMatrix,labels,'Outpatient',lfc=1)
UCIvsControl <- computeGenes_OVControl(expressionMatrix,labels,'ICU',lfc=1)
imvsControl <- computeGenes_OVControl(expressionMatrix,labels,'Inpatient',lfc=1)

#Check number of DEG per patient
plot(x=c(1:length(sapply(outvsControl,length))), y=sort(sapply(outvsControl,length)),xlab = 'Paciente ID',ylab = 'Número de DEGs')
plot(x=c(1:length(sapply(UCIvsControl,length))), y=sort(sapply(UCIvsControl,length)),xlab = 'Paciente ID',ylab = 'Número de DEGs')
plot(x=c(1:length(sapply(imvsControl,length))), y=sort(sapply(imvsControl,length)),xlab = 'Paciente ID',ylab = 'Número de DEGs')

#Check histogram distribution
hist(sapply(outvsControl,length), breaks = seq(from=0, to=700, by=30), main = "Outpatient vs Control", xlab = 'Número de DEGs', ylab = 'Número de pacientes')
hist(sapply(UCIvsControl,length), breaks = seq(from=0, to=500, by=50),main = "UCI vs Control", xlab = 'Número de DEGs', ylab = 'Número de pacientes')
hist(sapply(imvsControl,length), breaks = seq(from=300, to=600, by=50), main = "Inpatient vs Control",xlab = 'Número de DEGs', ylab = 'Número de pacientes')



#Get Inpatients DEGs with LFC=1.6
imvsControl2 <- computeGenes_OVControl(expressionMatrix,labels,'Inpatient',lfc=1.6)
imtvsControl.df2 <- data.frame(genes = unlist(imvsControl2))

#Check distribution and choose how many DEGs can be taken
genesAmount.ImvsControl2 <-length(names(sort(table(unlist(imvsControl2)))))
plot(x=c(1:genesAmount.ImvsControl), y=sort(table(unlist(imtvsControl.df))),xlab = 'genes',ylab = 'Appearances')
hist(sapply(imvsControl2,length), main = "Inpatient vs Control", xlab = 'Número de DEGs', ylab = 'Número de pacientes')



#Get Outpatients DEGs with LFC=1.6
outvsControl2 <- computeGenes_OVControl(expressionMatrix,labels,'Outpatient',lfc=0.95)
outtvsControl.df2 <- data.frame(genes = unlist(outvsControl2))

#Check distribution and choose how many DEGs can be taken
genesAmount.OutvsControl2 <-length(names(sort(table(unlist(outvsControl2)))))
plot(x=c(1:genesAmount.OutvsControl2), y=sort(table(unlist(outtvsControl.df2))),xlab = 'genes',ylab = 'Appearances')
hist(sapply(outvsControl2,length), breaks = seq(from=0, to=800, by=30), main = "Outpacient vs Control", xlab = 'Número de DEGs', ylab = 'Número de pacientes')


#Get UCI DEGs with LFC=1.1
UCIvsControl2 <- computeGenes_OVControl(expressionMatrix,labels,'ICU',lfc=1.1)
UCIvsControl.df2 <- data.frame(genes = unlist(UCIvsControl2))

#Check distribution and choose how many DEGs can be taken
genesAmount.UCIvsControl2 <-length(names(sort(table(unlist(UCIvsControl2)))))
plot(x=c(1:genesAmount.UCIvsControl2), y=sort(table(unlist(UCIvsControl.df2))),xlab = 'genes',ylab = 'Appearances')
hist(sapply(UCIvsControl2,length), breaks = seq(from=0, to=400, by=45), main = "UCI vs Control",xlab = 'Número de DEGs', ylab = 'Número de pacientes')

#Get n genes per group
Inpatient.DEGs <- imvsControl2
UCI.DEGs <- UCIvsControl2
Outpatient.DEGs <- outvsControl2

#Get LCF absoluto value
Inpatient.LFC.abs <- lapply(Inpatient.LFC, abs) 
UCI.LFC.abs <- lapply(UCI.LFC, abs)
Outpatient.LFC.abs <- lapply(Outpatient.LFC, abs)




