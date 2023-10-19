require(KnowSeq)
require(readxl)
require(GEOquery)
require(caret)
require(dplyr)
require(limma)
require(ROCR)
require(class)
set.seed(50)

# PREPROCESs.

# GSE156063
GSE156063 <- getGEO("GSE156063", destdir = 'GSE156063')
GSE156063_age <- round(as.numeric(GSE156063$GSE156063_series_matrix.txt.gz$`age:ch1`))
GSE156063_gender <- GSE156063$GSE156063_series_matrix.txt.gz$`gender:ch1`
GSE156063_rpm <- GSE156063$GSE156063_series_matrix.txt.gz$`sars-cov-2 pcr:ch1`
GSE156063_pcr <- GSE156063$GSE156063_series_matrix.txt.gz$`sars-cov-2 rpm:ch1`
GSE156063_labels <- GSE156063$GSE156063_series_matrix.txt.gz$`disease state:ch1`  
#Get genes counts
GSE156063_counts <- read.csv('GSE156063_swab_gene_counts.csv')
rownames <- GSE156063_counts[,1]
GSE156063_counts[,1] <- NULL
rownames(GSE156063_counts) <- rownames
Annotation_gene_GSE156063 <- getGenesAnnotation(rownames(GSE156063_counts))
Annotation_gene_GSE156063 <- Annotation_gene_GSE156063[order(Annotation_gene_GSE156063$ensembl_gene_id),]

#Build GSE156063 expressionMatrix
GSE156063_expressionMatrix <- calculateGeneExpressionValues(as.matrix(GSE156063_counts), Annotation_gene_GSE156063, genesNames = TRUE) # 

#Get severity labels
GSE156063_severity <- read_excel('Patient_class_inpatient_outpatient_MickKammetal.xlsx')

#Remove GSE156063 outliers
GSE156063_outliers <- RNAseqQA(GSE156063_expressionMatrix,toPNG = FALSE, toPDF = FALSE,toRemoval = TRUE)
GSE156063_age <- GSE156063_age[-which(colnames(GSE156063_expressionMatrix)%in%GSE156063_outliers$outliers)]
GSE156063_gender <- GSE156063_gender[-which(colnames(GSE156063_expressionMatrix)%in%GSE156063_outliers$outliers)]
GSE156063_rpm <- GSE156063_rpm[-which(colnames(GSE156063_expressionMatrix)%in%GSE156063_outliers$outliers)]
GSE156063_pcr <- GSE156063_pcr[-which(colnames(GSE156063_expressionMatrix)%in%GSE156063_outliers$outliers)]
GSE156063_labels <- GSE156063_labels[-which(colnames(GSE156063_expressionMatrix)%in%GSE156063_outliers$outliers)] 
GSE156063_severity <-  GSE156063_severity[-which(GSE156063_severity$CZB_ID%in%GSE156063_outliers$outliers),]
GSE156063_expressionMatrix <- GSE156063_outliers$matrix


#Pick interesting severity labels 
GSE156063_severity <- GSE156063_severity[which(GSE156063_severity$Viral_status=='SARS-CoV-2'),]
GSE156063_severity <- GSE156063_severity[which(GSE156063_severity$Patient_class=='Outpatient'|GSE156063_severity$Patient_class=='Inpatient'|GSE156063_severity$Patient_class=='Emergency'),]
GSE156063_age <- GSE156063_age[which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)]
GSE156063_gender <- GSE156063_gender[which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)]
GSE156063_rpm <- GSE156063_rpm[which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)]
GSE156063_pcr <- GSE156063_pcr[which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)]
GSE156063_labels <- GSE156063_labels[which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)] 
GSE156063_expressionMatrix <- GSE156063_expressionMatrix[,which(colnames(GSE156063_expressionMatrix)%in%GSE156063_severity$CZB_ID)]
GSE156063_age <- GSE156063_age[order(colnames(GSE156063_expressionMatrix))]
GSE156063_gender <- GSE156063_gender[order(colnames(GSE156063_expressionMatrix))]
GSE156063_rpm <- GSE156063_rpm[order(colnames(GSE156063_expressionMatrix))]
GSE156063_pcr <- GSE156063_pcr[order(colnames(GSE156063_expressionMatrix))]
GSE156063_expressionMatrix <- GSE156063_expressionMatrix[,order(colnames(GSE156063_expressionMatrix))]
GSE156063_severity <- GSE156063_severity[order(GSE156063_severity$CZB_ID),]
GSE156063_labels_severity <- GSE156063_severity$Patient_class
GSE156063_labels_severity[which(GSE156063_severity$ICU=='ICU')]<- 'ICU'

#Remove Emergency patients
GSE156063_expressionMatrix <- GSE156063_expressionMatrix[,-which(GSE156063_labels_severity=='Emergency')]
GSE156063_age <- GSE156063_age[-which(GSE156063_labels_severity=='Emergency')]
GSE156063_gender <- GSE156063_gender[-which(GSE156063_labels_severity=='Emergency')]
GSE156063_rpm <- GSE156063_rpm[-which(GSE156063_labels_severity=='Emergency')]
GSE156063_pcr <- GSE156063_pcr[-which(GSE156063_labels_severity=='Emergency')]
GSE156063_labels_severity <- GSE156063_labels_severity[-which(GSE156063_labels_severity=='Emergency')]

# GSE162835 
GSE162835 <- getGEO("GSE162835", destdir = 'GSE162835')
GSE162835_sup <- as.data.frame(read_excel('sup_info.xlsx'))
GSE162835_age <- GSE162835_sup$...2[3:52]
GSE162835_gender <- GSE162835_sup$...3[3:52]
GSE162835_labels <- GSE162835$GSE162835_series_matrix.txt.gz$`disease:ch1`
for (i in 1:50){
  GSE162835_labels[i] <- 'SC2' 
}
GSE162835_labels_severity <- GSE162835$GSE162835_series_matrix.txt.gz$`disease severity:ch1`
for (i in 1:length(GSE162835_labels_severity)){
  if (GSE162835_labels_severity[i]=='Asymptomatic/Mild'){
    GSE162835_labels_severity[i] <- 'Outpatient'
  } else if (GSE162835_labels_severity[i]=='Moderate'){
    GSE162835_labels_severity[i] <- 'Inpatient'
  } else if (GSE162835_labels_severity[i]=='Severe/Critical'){
    GSE162835_labels_severity[i] <- 'ICU'
  }
}

#Build expression matrix
GSE162835_expressionMatrix <- as.matrix(read_excel('GSE162835_COVID_GEO_processed.xlsx'))
rownames <- GSE162835_expressionMatrix[,1]
rownames(GSE162835_expressionMatrix) <- rownames
GSE162835_expressionMatrix <- GSE162835_expressionMatrix[,2:51]
GSE162835_expressionMatrix <- apply(GSE162835_expressionMatrix,2,as.numeric)
rownames(GSE162835_expressionMatrix) <- rownames

#Remove outliers
GSE162835_outliers <- RNAseqQA(GSE162835_expressionMatrix,toPNG = FALSE, toPDF = FALSE,toRemoval = TRUE) 
GSE162835_labels <- GSE162835_labels[-which(colnames(GSE162835_expressionMatrix) %in% GSE162835_outliers$outliers)]
GSE162835_labels_severity <- GSE162835_labels_severity[-which(colnames(GSE162835_expressionMatrix) %in% GSE162835_outliers$outliers)]
GSE162835_expressionMatrix <- GSE162835_outliers$matrix
GSE162835_age <- GSE162835_age[-c(48,50)]
GSE162835_gender <- GSE162835_gender[-c(48,50)]

# GSE152075
GSE152075 <- getGEO("GSE152075", destdir = 'GSE152075')
GSE152075_age <- GSE152075$GSE152075_series_matrix.txt.gz$`age:ch1`
GSE152075_gender <- GSE152075$GSE152075_series_matrix.txt.gz$`gender:ch1`
GSE152075_labels <- GSE152075$GSE152075_series_matrix.txt.gz$`sars-cov-2 positivity:ch1`
for (i in 1:length(GSE152075_labels)){
  if (GSE152075_labels[i] == 'pos'){
    GSE152075_labels[i] <- 'SC2'
  } else {
    GSE152075_labels[i] <- 'Control'
  }
}

#Get counts
GSE152075_counts <- as.matrix(read.table('GSE152075_raw_counts_GEO.txt', header =TRUE))
Annotation_gene_GSE152075 <- getGenesAnnotation(rownames(GSE152075_counts), filter = 'external_gene_name')
Annotation_gene_GSE152075 <- Annotation_gene_GSE152075[order(Annotation_gene_GSE152075$external_gene_name),]
GSE152075_counts<- GSE152075_counts[order(rownames(GSE152075_counts)),]
GSE152075_counts_1 <- GSE152075_counts[which(rownames(GSE152075_counts) %in% Annotation_gene_GSE152075[,2]),]
for (i in 1:length(rownames(GSE152075_counts_1))){
  rownames(GSE152075_counts_1)[i] <- Annotation_gene_GSE152075[which(Annotation_gene_GSE152075[,2] == rownames(GSE152075_counts_1)[i])[1],1] 
}
Annotation_gene_GSE152075_1 <- getGenesAnnotation(rownames(GSE152075_counts_1))
Annotation_gene_GSE152075_1 <- Annotation_gene_GSE152075_1[order(Annotation_gene_GSE152075_1$ensembl_gene_id),]
GSE152075_counts_1<- GSE152075_counts_1[order(rownames(GSE152075_counts_1)),]

#Build expression matrix
GSE152075_expressionMatrix <- calculateGeneExpressionValues(GSE152075_counts_1, Annotation_gene_GSE152075_1, genesNames = TRUE) #

#Get severity labels
GSE152075_severity <- read.csv('2021-03-19_Rojas.csv')

#Remove outliers
GSE152075_outliers <- RNAseqQA(GSE152075_expressionMatrix,toPNG = FALSE, toPDF = FALSE,toRemoval = TRUE) # 
GSE152075_age <- GSE152075_age[-which(colnames(GSE152075_expressionMatrix)%in%GSE152075_outliers$outliers)]
GSE152075_gender <- GSE152075_gender[-which(colnames(GSE152075_expressionMatrix)%in%GSE152075_outliers$outliers)]
GSE152075_labels <- GSE152075_labels[-which(colnames(GSE152075_expressionMatrix)%in%GSE152075_outliers$outliers)] 
GSE152075_severity <-  GSE152075_severity[-which(GSE152075_severity$ï..alt_name%in%GSE152075_outliers$outliers),]
GSE152075_expressionMatrix <- GSE152075_outliers$matrix
GSE152075_severity <- GSE152075_severity[which(GSE152075_severity$covid_status=='pos'),]
GSE152075_severity <- GSE152075_severity[which(GSE152075_severity$admitted.to.hospital..not.just.ED..at.time.of.initial.test.=='yes'|GSE152075_severity$admitted.to.hospital..not.just.ED..at.time.of.initial.test.=='no'),]
GSE152075_expressionMatrix_severity <- GSE152075_expressionMatrix[,which(colnames(GSE152075_expressionMatrix)%in%GSE152075_severity$ï..alt_name)]
GSE152075_expressionMatrix_severity <- cbind(GSE152075_expressionMatrix_severity,GSE152075_expressionMatrix[,which(GSE152075_labels=='Control')])
GSE152075_labels_severity <- c(GSE152075_severity$admitted.to.hospital..not.just.ED..at.time.of.initial.test., rep('Control',52))
for (i in 1:length(GSE152075_labels_severity)){
  if (GSE152075_labels_severity[i]=='no'){
    GSE152075_labels_severity[i]<-'Outpatient'
  } else if (GSE152075_labels_severity[i]=='yes'){
    GSE152075_labels_severity[i]<-'Inpatient'
  }
}
GSE152075_labels_severity[which(GSE152075_severity$ICU=='yes')]<- 'ICU'


##Join 3 expression matrixes
I1 <- intersect(rownames(GSE156063_expressionMatrix), rownames(GSE152075_expressionMatrix_severity))
I2 <- intersect(I1, rownames(GSE162835_expressionMatrix))
GSE156063_I <- GSE156063_expressionMatrix[which(rownames(GSE156063_expressionMatrix) %in%  I2),]
GSE152075_I <- GSE152075_expressionMatrix_severity[which(rownames(GSE152075_expressionMatrix_severity) %in%  I2),]
GSE162835_I <- GSE162835_expressionMatrix[which(rownames(GSE162835_expressionMatrix) %in%  I2),]
GSE156063_I <- GSE156063_I[order(rownames(GSE156063_I)),] 
GSE152075_I <- GSE152075_I[order(rownames(GSE152075_I)),] 
labels <- c(GSE156063_labels_severity,GSE152075_labels_severity,GSE162835_labels_severity)
expression_matrix <- cbind(GSE156063_I,GSE152075_I,GSE162835_I)

#Normalization between arrays
expression_matrix_norm_scale <- normalizeBetweenArrays(expression_matrix, method = 'scale')

#Remove batch effect
expression_matrix_norm_scale_fix <- batchEffectRemoval(expression_matrix_norm_scale,labels, method = 'sva')

#Remove outliers
outliers_scale <- RNAseqQA(expression_matrix_norm_scale_fix,toRemoval = TRUE, toPNG = FALSE, toPDF = FALSE) #3
expressionMatrix <- expression_matrix_norm_scale_fix[,-which(colnames(expression_matrix_norm_scale_fix) %in% outliers_scale$outliers)]
labels <- labels[-which(colnames(expression_matrix_norm_scale_fix) %in% outliers_scale$outliers)]
