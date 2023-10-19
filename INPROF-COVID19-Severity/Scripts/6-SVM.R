require(KnowSeq)
require(caret)

#Train SVM with 2 first mRMR features
svm.2features <- svm_trn(data=data.alignment.final[,-44],
                         labels = data.alignment.final$label,
                         vars_selected = names(feature.ranking.alignment)[1:2],
                         numFold = 159)

svm.accuracy.means= c()
svm.accuracy.sds = c()
confusion.matrixes <- vector(mode = "list", length = 43)

confusion.matrixes.sorted <- confusion.matrixes

#Train all SVM models using mRMR variables incrementaly
for (i in c(2:43)){
  print(i)
  model<-svm_trn(data=data.alignment.final[,-44],
                 labels = data.alignment.final$label,
                 vars_selected = names(feature.ranking.alignment)[1:i],
                 numFold = 159)
  confusion.matrix = svm.2features$cfMats[[1]]$table
  confusion.matrix[2,2] = 0
  svm.accuracy.means<- c(svm.accuracy.means, model$accuracyInfo$meanAccuracy)
  svm.accuracy.sds <- c(svm.accuracy.sds, model$accuracyInfo$standardDeviation)
  for (j in c(1:159)){
    confusion.matrix <- confusion.matrix+model$cfMats[[j]]$table
  }
  confusion.matrixes[[i]]<-confusion.matrix
}

for (i in c(1:43)){
  aux<-confusion.matrixes[[i]][c(2,1,3),c(2,1,3)]
  confusion.matrixes.sorted[[i]]<-aux
}

#Get quality measures
accuracies <- c()
sensitivity.IN <- c()
sensitivity.OUT <- c()
sensitivity.UCI <- c()

specificity.UCI <- c()
specificity.OUT <- c()
specificity.IN <- c()

f1.UCI <- c()
f1.OUT <- c()
f1.IN <- c()

precision.UCI <- c()
precision.OUT <- c()
precision.IN <- c()

for (i in c(2:43)){
  stats <- confusionMatrix(confusion.matrixes[[i]])
  accuracies <- c(accuracies,stats$overall[1])
  
  sensitivity.IN <- c(sensitivity.IN, stats$byClass[1,1])
  sensitivity.OUT <- c(sensitivity.OUT, stats$byClass[2,1])
  sensitivity.UCI <- c(sensitivity.UCI, stats$byClass[3,1])
  
  specificity.IN <- c(specificity.IN, stats$byClass[1,2])
  specificity.OUT <- c(specificity.OUT, stats$byClass[2,2])
  specificity.UCI <- c(specificity.UCI, stats$byClass[3,2])
  
  f1.IN <- c(f1.IN, stats$byClass[1,7])
  f1.OUT <- c(f1.OUT, stats$byClass[2,7])
  f1.UCI <- c(f1.UCI, stats$byClass[3,7])
  
  precision.UCI <- c(precision.UCI, stats$byClass[1,5])
  precision.OUT <- c(precision.OUT, stats$byClass[2,5])
  precision.IN <- c(precision.IN, stats$byClass[3,5])
}

names(accuracies)<-NULL

#Plot them
x<-c(2:43)

plot(x,accuracies,cex = .8,pch=1,xlab="x axis",ylab="y axis",col="blue",type = 'line')
title('Accuracy')

plot(x,sensitivity.IN,cex = .8,xlab="Amount of Features",ylab="Sensitivity",col="blue",type = 'line',ylim = c(0.2,1))
lines(x,sensitivity.OUT,cex = .8,col="red")
lines(x,sensitivity.UCI,cex = .8,col="green")
title('Sensitivity')
legend(x=25,y=0.4,c("IN","OUT",'UCI'),cex=1.2,col=c("blue","red","green"),pch=c(1,1,1))

plot(x,specificity.IN,cex = .8,xlab="Amount of Features",ylab="Specificity",col="blue",type = 'line',ylim = c(0.5,1))
lines(x,specificity.OUT,cex = .8,col="red")
lines(x,specificity.UCI,cex = .8,col="green")
title('Specificity')
legend(x=25,y=0.6,c("IN","OUT",'UCI'),cex=1.2,col=c("blue","red","green"),pch=c(1,1,1))

plot(x,f1.IN,cex = .8,xlab="Amount of Features",ylab="F1-Score",col="blue",type = 'line',ylim = c(0.4,1))
lines(x,f1.OUT,cex = .8,col="red")
lines(x,f1.UCI,cex = .8,col="green")
title('F1-Score')
legend(x=25,y=0.6,c("IN","OUT",'UCI'),cex=1.2,col=c("blue","red","green"),pch=c(1,1,1))

plot(x,precision.IN,cex = .8,xlab="Amount of Features",ylab="Precision",col="blue",type = 'line',ylim = c(0.5,1))
lines(x,precision.OUT,cex = .8,col="red")
lines(x,precision.UCI,cex = .8,col="green")
title('Precision')
legend(x=25,y=0.6,c("IN","OUT",'UCI'),cex=1.2,col=c("blue","red","green"),pch=c(1,1,1))


f1.weighted<-(18*f1.IN+130*f1.OUT+11*f1.UCI)/159
sensitivity.weighted<-(18*sensitivity.IN+130*sensitivity.OUT+11*sensitivity.UCI)/159
specificity.weighted<-(18*specificity.IN+130*specificity.OUT+11*specificity.UCI)/159
precision.weighted<-(18*precision.IN+130*precision.OUT+11*precision.UCI)/159

plot(x,f1.weighted,cex = .8,xlab="Amount of Features",ylab="Value",col="blue",type = 'line',ylim = c(0.65,1))
lines(x,sensitivity.weighted,cex = .8,col="red")
lines(x,specificity.weighted,cex = .8,col="green")
lines(x,precision.weighted,cex = .8,col="black")
title('Weighted Metrics')
legend(x=32,y=0.75,c("F1","Sensitivity",'Specificity', 'Precision'),
       cex=1.2,col=c("blue","red","green",'black'),pch=c(1,1,1,1))
