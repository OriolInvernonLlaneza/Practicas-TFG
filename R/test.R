library("NLP")
library("tm") #load text mining library
library("fastmatch")
library("XML")
library("stringr")
library("cluster")
library("fpc")
library("dbscan")
library("factoextra")
library("tidytext")
library("topicmodels")
library("doParallel")
library("ggplot2")
library("scales")
library("tidytext")
#library("RColorBrewer")
#library("wordcloud2")
#library("RTextTools")

setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
#setwd("C:/Users/Becario-2/Desktop/RepoOri1718/practicas/Practicas-TFG/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

#ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
csv <- read.csv("cartas\\CorrespondenciaJove.csv", sep =";", header = TRUE, encoding = "UTF-8")
ex <- VCorpus(VectorSource(csv$TextoCarta[1:205]))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #numbers
  corpus <- tm_map(corpus, removePunctuation) #punt
  corpus <- tm_map(corpus, content_transformer(function(n) { n <- gsub("[¡¿'«»]", "", n)}))
  corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), customStopwords, "al")) #stopwords
  corpus <- tm_map(corpus, stripWhitespace) #extra whitespace
  #corpus <- tm_map(corpus, PlainTextDocument)  # needs to come before stemming
  return(corpus)
}

clean <- cleanCorpus(ex)
cleanCopy <- clean

source("lematizador.r")
stemCustom <- function(x) {
  if(x=="") {
    return()
  }
  for(i in 1:length(x)) {
    l <- unlist(strsplit(x[[i]], " "))
    for(j in 1:length(l)){
      aux <- lematizador(l[[j]])
      #print(aux)
      if(!is.na(aux)) {
        l[[j]] <- aux
      }
      #print(l[[j]])
    }
    #str(l)
    x[[i]] <- paste(unlist(l), collapse=" ")
    #x[[i]] <- iconv(paste(unlist(l), collapse=" "), from = "UTF8", to = "UTF8")
    #str(x[[i]])
  }
  return(x)
}

stemmed <- tm_map(clean, content_transformer(stemCustom))
inspect(stemmed[[1]])

#stemmed <- tm_map(stemmed, content_transformer(function(x) iconv(enc2utf8(x), sub = "byte")))
#inspect(stemmed[[40]])

dtm <- DocumentTermMatrix(stemmed) #matrix
#inspect(dtm)
write.csv(as.matrix(dtm), 'dtm.csv')
#word list
words <- dtm$dimnames$Terms
words <- words[order(words)]
write.table(words,"words.txt",sep="\t",row.names=FALSE)

findFreqTerms(dtm, lowfreq = 100) #buscar términos más comunes en matriz
sparse <- removeSparseTerms(dtm, 0.99) #remove low freq words
mOG <- as.matrix(dtm)
m <- as.matrix(sparse)

#k means algorithm 1
d <- dist(m)
fviz_nbclust(as.matrix(d), kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
kfit <- kmeans(d, 3, nstart=100)
plot(prcomp(d)$x, col=kfit$cl)
fviz_cluster(kfit, d, ellipse = FALSE, geom = "point")
#clusplot(m, kfit$cluster, color=T, shade=T, labels=2, lines=0)
kfitm <- kmeans(m, 4, nstart=100)
fviz_cluster(kfitm, m, ellipse = FALSE, geom = "point")

#k means algorithm 2
tfxidf <- weightTfIdf(sparse, normalize = TRUE) #norm true for eucli
m_norm <- as.matrix(tfxidf)
rownames(m_norm) <- 1:nrow(m_norm)
fviz_nbclust(as.matrix(m_norm), kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
cl <- kmeans(m_norm, 5)
### show clusters using the first 2 principal components
plot(prcomp(m_norm)$x, col=cl$cl)

#hierarchical
h1 <- agnes(prcomp(m_norm)$x, metric = "euclidean", stand = FALSE)
h2 <- diana(prcomp(m_norm)$x, metric = "euclidean", stand = FALSE)
pltree(h1, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h2, cex = 0.6, hang = -1, main = "Dendrograma de diana")

h11 <- agnes(m, stand = FALSE)
h22 <- diana(m, stand = FALSE)
pltree(h11, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h22, cex = 0.6, hang = -1, main = "Dendrograma de diana")

h111 <- agnes(d, metric = "euclidean", stand = FALSE)
h222 <- diana(d, metric = "euclidean", stand = FALSE)
pltree(h111, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h222, cex = 0.6, hang = -1, main = "Dendrograma de diana")

#density
kNNdistplot(mOG, k = 3)
abline(h = 25, lty = 2)
db <- dbscan(m, 25, 3)
fviz_cluster(db, data = mOG, stand = FALSE,
             ellipse = TRUE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())
kNNdistplot(m, k = 3)
abline(h = 25, lty = 2)
db <- dbscan(m, 25, 3)
fviz_cluster(db, data = m, stand = FALSE,
             ellipse = TRUE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())
tfxidf <- weightTfIdf(dtm, normalize = TRUE)
kNNdistplot(tfxidf, k = 3)
abline(h = 1.4, lty = 2)
db <- dbscan(as.matrix(tfxidf), 1.4, 3)
fviz_cluster(db, data = as.matrix(tfxidf), stand = FALSE,
             ellipse = FALSE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())

#----------------5-fold cross-validation, different numbers of topics----------------
# set up a cluster for parallel processing
cluster <- makeCluster(detectCores(logical = TRUE) - 1) # leave one CPU spare...
registerDoParallel(cluster)

# load up the needed R package on all the parallel sessions
clusterEvalQ(cluster, {
  library(topicmodels)
})

full_data <- sparse
n <- nrow(full_data)
burnin <- 4000
iter <- 1500
keep <- 50
folds <- 5
splitfolds <- sample(1:folds, n, replace = TRUE)
candidate_k <- c(5, 7, 10, 15, 20, 23, 25, 30, 40, 50, 75, 100, 200, 300) # candidates for how many topics

# export all the needed R objects to the parallel sessions
clusterExport(cluster, c("full_data", "burnin", "iter", "keep", "splitfolds", "folds", "candidate_k"))

# we parallelize by the different number of topics.  A processor is allocated a value
# of k, and does the cross-validation serially.  This is because it is assumed there
# are more candidate values of k than there are cross-validation folds, hence it
# will be more efficient to parallelise
system.time({
  results <- foreach(j = 1:length(candidate_k), .combine = rbind) %dopar%{
    k <- candidate_k[j]
    results_1k <- matrix(0, nrow = folds, ncol = 2)
    colnames(results_1k) <- c("k", "perplexity")
    for(i in 1:folds){
      train_set <- full_data[splitfolds != i , ]
      valid_set <- full_data[splitfolds == i, ]
      
      fitted <- LDA(train_set, k = k, method = "Gibbs",
                    control = list(burnin = burnin, iter = iter, keep = keep) )
      results_1k[i,] <- c(k, perplexity(fitted, newdata = valid_set))
    }
    return(results_1k)
  }
})
stopCluster(cluster)

results_df <- as.data.frame(results)

ggplot(results_df, aes(x = k, y = perplexity)) +
  geom_point() +
  geom_smooth(se = FALSE) +
  ggtitle("5-fold cross-validation of topic modelling with the 'CartasJove' dataset") +
  labs(x = "Candidate number of topics", y = "Perplexity when fitting the trained model to the hold-out set")

#Topic modeling
#Set parameters for Gibbs sampling
burnin <- 4000
iter <- 1500
thin <- 50
seed <-list(2003,5,63,100001,765)
nstart <- 5
best <- TRUE
set.seed(10)
#Number of topics
k <- 7
ldaOut <-LDA(m, k, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))
#write out results
#docs to topics
ldaOut.topics <- as.matrix(topics(ldaOut))
write.csv(ldaOut.topics,file=paste("TopicModel/LDAGibbsSparse99",k,"DocsToTopics.csv"))
#top 10 terms in each topic
ldaOut.terms <- as.matrix(terms(ldaOut,10))
write.csv(ldaOut.terms,file=paste("TopicModel/LDAGibbsSparse99",k,"TopicsToTerms.csv"))
#probabilities associated with each topic assignment
topicProbabilities <- as.data.frame(ldaOut@gamma)
write.csv(topicProbabilities,file=paste("TopicModel/LDAGibbsSparse99",k,"TopicProbabilities.csv"))
#Find relative importance of top 2 topics
topic1ToTopic2 <- lapply(1:nrow(dtm),function(x){
      sort(topicProbabilities[x,])[k]/sort(topicProbabilities[x,])[k-1]})
#Find relative importance of second and third most important topics
topic2ToTopic3 <- lapply(1:nrow(dtm),function(x) {
        sort(topicProbabilities[x,])[k-1]/sort(topicProbabilities[x,])[k-2]})
#write to file
write.csv(topic1ToTopic2,file=paste("TopicModel/LDAGibbsSparse99",k,"Topic1ToTopic2.csv"))
write.csv(topic2ToTopic3,file=paste("TopicModel/LDAGibbsSparse99",k,"Topic2ToTopic3.csv"))

jo_topics <- tidy(ldaOut, matrix = "beta")
library(ggplot2)
library(dplyr)

ap_top_terms <- jo_topics %>%
  group_by(topic) %>%
  top_n(6, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()

#sparcl
library("sparcl")
hscA <- HierarchicalSparseCluster(as.matrix(dtm), method = "average", niter=15 ,dissimilarity = "squared.distance")
hscC <- HierarchicalSparseCluster(as.matrix(dtm), method = "complete", niter=15 ,dissimilarity = "squared.distance")
hscS <- HierarchicalSparseCluster(as.matrix(dtm), method = "single", niter=15 ,dissimilarity = "squared.distance")
hscCT <- HierarchicalSparseCluster(as.matrix(dtm), method = "centroid", niter=15 ,dissimilarity = "squared.distance")
ksc <- KMeansSparseCluster(m, K=5, wbounds = NULL, nstart = 20, silent =
                      FALSE, maxiter=6, centers=NULL)
plot(hscA)
plot(hscC)
plot(hscS)
plot(hscCT)