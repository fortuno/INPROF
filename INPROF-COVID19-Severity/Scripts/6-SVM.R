require(KnowSeq)
require(caret)
library(ggplot2)
library(dplyr)
library(tidyr)
set.seed(35)

# Load ranking and INPROF feature matrix
load("../Data/inprof_features_filtered.Rdata")
load("../Data/inprof_features_ranking.Rdata")

label_col <- which(colnames(data.alignment.filtered) == "label")
total_feats <- label_col-1
nfolds <- 5

########################################
# LEAVE 20% TEST Y TRAIN WITH CV FOLD-5
########################################

# Order randomly
testRandomPos <- createDataPartition(data.alignment.filtered$label, times=1, p=0.2)
testData <- data.alignment.filtered[testRandomPos$Resample1,]
trainData <- data.alignment.filtered[-testRandomPos$Resample1,]
  
# Train features with a 5-CV
svm.trn.stats <- svm_trn(data=trainData[,-label_col],
                         labels = trainData$label,
                         vars_selected = names(feature.ranking.alignment),
                         numFold = nfolds)

# Get metrics into a dataframe
accuracy_df <- data.frame(Features = 1:total_feats, Metric="Accuracy", 
                          Value=svm.trn.stats$accuracyInfo$meanAccuracy)
sensitivity_df <- data.frame(Features = 1:total_feats, Metric="Sensitivity",  
                             Value=svm.trn.stats$sensitivityInfo$meanSensitivity)
specificity_df <- data.frame(Features = 1:total_feats, Metric="Specificity",  
                             Value=svm.trn.stats$specificityInfo$meanSpecificity)
f1score_df <- data.frame(Features = 1:total_feats, Metric="F1-Score",  
                         Value=svm.trn.stats$F1Info$meanF1)
svm.trn.progression <- rbind(accuracy_df, sensitivity_df, specificity_df, f1score_df)

# Plot progression
p <- ggplot(svm.trn.progression, aes(x = Features, y = Value, color = Metric, linetype = Metric)) +
  geom_line(size = 1) +
  theme_bw(base_size = 14) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    x = "Features Selected",
    y = "Metric Value"
  ) +
  theme(
    legend.title = element_blank(),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

# Save plot
ggsave("../Plots/SVM_training_progression.png", plot = p, width = 6, height = 4, dpi = 300)

# Test with the remaining 20%
num_feats <- 10
svm.test.stats <- svm_test(trainData[,-label_col], trainData$label,
                           testData[,-label_col], testData$label,
                           vars_selected = names(feature.ranking.alignment[1:f]),
                           svm.trn.stats$bestParameters)
    
# Get confusion matrix for selected features
confMatrix <- svm.test.stats$cfMats[[f]]$table
colnames(confMatrix) <- c("Inpatient", "Outpatient", "ICU")
rownames(confMatrix) <- c("Inpatient", "Outpatient", "ICU")
png("../Plots/SVM_test_confusion_matrix.png", width = 860, height = 800, pointsize=27)
dataPlot(data=confMatrix, labels=colnames(confMatrix), mode = "confusionMatrix")
dev.off()


##################################
# LEAVE ONE OUT CROSS VALIDATION
##################################
num_feats <- 10
svm.loocv.features <- svm_trn(data=data.alignment.filtered[,-label_col],
                              labels = data.alignment.filtered$label,
                              vars_selected = names(feature.ranking.alignment)[1:num_feats],
                              numFold = 159)

# Get final confusion matrix
loocv.confmatrix <- svm.loocv.features$cfMats[[1]]$table
for (i in 2:length(svm.loocv.features$cfMats)){
  loocv.confmatrix <- loocv.confmatrix + svm.loocv.features$cfMats[[i]]$table
}
colnames(loocv.confmatrix) <- c("Inpatient", "Outpatient", "ICU")
rownames(loocv.confmatrix) <- c("Inpatient", "Outpatient", "ICU")

# Plot confusion matrix
png(paste0("../Plots/SVM_loocv_confusion_matrix.png"), width = 860, height = 800, pointsize=27)
dataPlot(data=loocv.confmatrix, labels=colnames(loocv.confmatrix), mode = "confusionMatrix")
dev.off()

############################################
# COMPARISON WITH RESULTS IN OTHER ARTICLE:
# DOI: 10.2174/1574893617666220718110053
############################################

# Matrix extracted from manuscript (Fig.5, removing "Control" group)
prev.confmatrix <- matrix(c(10,0,1,0,18,0,3,1,126),3,3)
colnames(prev.confmatrix) <- c("ICU", "Inpatient", "Outpatient")
rownames(prev.confmatrix) <- c("ICU", "Inpatient", "Outpatient")

# Plot compared confusion matrix
png(paste0("../Plots/DEGs_confusion_matrix.png"), width = 860, height = 800, pointsize=27)
dataPlot(prev.confmatrix, labels=colnames(prev.confmatrix), mode="confusionMatrix")
dev.off()


############################################
# TOP FEATURES BOXPLOTS
############################################

# Prepare dataframe of values
data.alignment.filtered$label <- factor(data.alignment.filtered$label)
levels(data.alignment.filtered$label) <- c("Inpatient", "Outpatient", "ICU")
top_feats <- names(feature.ranking.alignment)[1:6]

# Join the three top features
df_long <- data.alignment.filtered %>%
  pivot_longer(all_of(top_feats), names_to = "feature", values_to = "value")
df_long$feature <- factor(df_long$feature, levels=top_feats)

# Plot
bx <- ggplot(df_long, aes(x = label, y = value, fill = label)) +
      geom_boxplot(outlier.shape = NA, alpha = 0.8, width = 0.6, color = "black") +
      geom_jitter(aes(color = label), width = 0.15, size = 1.6, alpha = 0.5) +
      facet_wrap(~ feature, scales = "free_y", ncol = 3) +
      scale_fill_brewer(palette = "Set2") +
      scale_color_brewer(palette = "Set2") +
      labs(x = "", y = "Value", title = "Top Feature Distributions") +
      theme_minimal(base_size = 12) +
      theme(
        legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        axis.title = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.line = element_line(colour = "black"),
        axis.ticks = element_line(colour = "black")
  )
bx
# Save plot
ggsave("../Plots/Top_Boxplot.png", plot = bx, width =9, height = 4, dpi = 300)


