library("NLP")
library("tm") #load text mining library
library("fastmatch")
library("XML")
library("stringr")
library("cluster")
library("fpc")
library("dbscan")
library("factoextra")
#library("RColorBrewer")
#library("wordcloud2")
#library("RTextTools")

setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

#ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
csv <- read.csv("cartas\\CorrespondenciaJove.csv", sep =";", header = TRUE, encoding = "UTF-8")
ex <- VCorpus(VectorSource(csv$TextoCarta[1:50]))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #numbers
  corpus <- tm_map(corpus, removePunctuation) #punt
  corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), customStopwords)) #stopwords
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
    #str(x[[i]])
  }
  return(x)
}

stemmed <- tm_map(clean, content_transformer(stemCustom))
inspect(stemmed[[1]])

stemmed <- tm_map(stemmed, content_transformer(function(x) iconv(enc2utf8(x), sub = "byte")))

inspect(stemmed[[40]])

dtm <- DocumentTermMatrix(stemmed) #matrix
findFreqTerms(dtm, lowfreq = 30) #buscar términos más comunes en matriz
#sparse = removeSparseTerms(dtm, 0.90) #remove low freq words

#k means algorithm 1
m <- as.matrix(dtm)
d <- dist(m)
fviz_nbclust(as.matrix(d), kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
kfit <- kmeans(d, 2, nstart=100)
plot(prcomp(d)$x, col=kfit$cl)
#clusplot(m, kfit$cluster, color=T, shade=T, labels=2, lines=0)

#k means algorithm 2
tfxidf <- weightTfIdf(dtm, normalize = TRUE) #norm true for eucli
m_norm <- as.matrix(tfxidf)
rownames(m2) <- 1:nrow(m2)
fviz_nbclust(as.matrix(m_norm), kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
cl <- kmeans(m_norm, 5)
### show clusters using the first 2 principal components
plot(prcomp(m_norm)$x, col=cl$cl)

#hierarchical agnes
h1 <- agnes(prcomp(m_norm)$x, metric = "euclidean", stand = FALSE)
h2 <- diana(prcomp(m_norm)$x, metric = "euclidean", stand = FALSE)
pltree(h1, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h2, cex = 0.6, hang = -1, main = "Dendrograma de diana")

#density

