require(Rtsne)
require(KnowSeq)

#Apply t-SNE
train<-  data.alignment.final
Labels<-train$label
train$label<-as.factor(train$label)
tsne <- Rtsne(train[,-c(44)], dims = 2, perplexity=30, verbose=TRUE,
              max_iter = 500,check_duplicates=FALSE,pca=FALSE,pca_center = FALSE,pca_scale=FALSE)

## Plot t-SNE reduction
x.uci<-tsne$Y[,1][c(1:11)]
y.uci<-tsne$Y[,2][c(1:11)]

x.in<-tsne$Y[,1][c(142:159)]
y.in<-tsne$Y[,2][c(142:159)]

x.out<-tsne$Y[,1][c(12:141)]
y.out<-tsne$Y[,2][c(12:141)]
plot(x.out,y.out,cex = .8,pch=1,xlab="x axis",ylab="y axis",col="blue",xlim = c(-10,10))
points(x.in,y.in,cex = .8,pch=2,col="red")
points(x.uci,y.uci,cex = .8,pch=3,col="green")

legend(x=3,y=0,c("In (18)","Out (130)", "UCI (11)"),cex=1.2,col=c("red","blue","green"),pch=c(2,1,3))

#get mRMR ranking
feature.ranking.alignment <- featureSelection(
  data = data.alignment.final[,-44],
  labels = data.alignment.final$label,
  vars_selected = variable.names(data.alignment.final)[-44],
  mode = "mrmr")


