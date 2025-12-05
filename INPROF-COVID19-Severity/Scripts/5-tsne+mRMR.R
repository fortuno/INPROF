require(Rtsne)
require(KnowSeq)
require(ggplot2)
set.seed(35)

# Load joined matrix from previous script
load("../Data/inprof_features_final.Rdata")
data.alignment.final[is.na(data.alignment.final)]<-0
label_col <- which(colnames(data.alignment.final) == "label")

# Save matrix as table
write.table(data.alignment.final, file="../Data/inprof_features_matrix.tsv", 
            row.names=FALSE, sep="\t")

#Apply t-SNE
train<-  data.alignment.final
train$label<-as.factor(train$label)
tsne <- Rtsne(train[,-c(label_col)], dims = 2, perplexity=50, verbose=TRUE,
              max_iter = 1000,check_duplicates=FALSE,pca=FALSE,pca_center = FALSE,pca_scale=FALSE)

# Convert to data.frame and add labels
tsne_df <- data.frame(tsne$Y)
tsne_df$Group <- train$label
levels(tsne_df$Group) <- c("Inpatient", "Outpatient", "ICU")

# Define custom colors and shapes
group_colors <- c("Outpatient" = "#1F77B4",  # blue
                  "Inpatient"  = "#D62728",  # red
                  "ICU"        = "#2CA02C")  # green
group_shapes <- c("Outpatient" = 16, "Inpatient" = 17, "ICU" = 15)


# Plot TSNE
p <- ggplot(tsne_df, aes(x = X1, y = X2, color = Group, shape = Group)) +
  geom_point(size = 2.8, alpha = 0.6) +
  scale_color_manual(values = group_colors) +
  scale_shape_manual(values = group_shapes) +
  theme_bw(base_size = 14) +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    legend.text=element_text(size=14),
    panel.grid.major = element_line(color = "grey70", size = 0.3),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold"),
    plot.margin = margin(10, 10, 10, 10)
  ) +
  labs(
    x = "t-SNE Component 1",
    y = "t-SNE Component 2",
  )

# Save plot
ggsave("../Plots/TSNE_COVID19_groups.png", plot = p, width = 6, height = 5, dpi = 300)

# Remove features with mostly 0s
high_rep_feats <- sapply(data.alignment.final[,-label_col], function(x) sum(x!=0)) >10
data.alignment.filtered <- data.alignment.final[,c(high_rep_feats,TRUE)]
label_col_filt <- which(colnames(data.alignment.filtered) == "label")

#get mRMR ranking
feature.ranking.alignment <- featureSelection(
  data = data.alignment.filtered[,-label_col_filt],
  labels = data.alignment.filtered$label,
  vars_selected = variable.names(data.alignment.filtered[,-label_col_filt]),
  mode = "mrmr")

# Save final filters after low variation removal and mRMR ranking
save(list = c("data.alignment.filtered"), file = "../Data/inprof_features_filtered.Rdata")
save(list = c("feature.ranking.alignment"), file = "../Data/inprof_features_ranking.Rdata")
