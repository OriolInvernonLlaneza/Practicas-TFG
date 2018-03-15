library("NLP")
library("tm") #load text mining library
library("RColorBrewer")
library("wordcloud2")
library("RTextTools")

setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #números
  corpus <- tm_map(corpus, removePunctuation) #puntuación
  corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), customStopwords)) #Borrar palabras vacías.
  corpus <- tm_map(corpus, stripWhitespace) #espacios en blanco extras
  corpus <- tm_map(corpus, PlainTextDocument)  # needs to come before stemming
  return(corpus)
}

clean <- cleanCorpus(ex)
cleanCopy <- clean
stemmed <- tm_map(clean, stemDocument, "spanish")
#stemmedC <- tm_map(stemmed, stemCompletion, dictionary=cleanCopy)

inspect(ex[[1]])

matrix <-DocumentTermMatrix(ex) #matriz
findFreqTerms(matrix, lowfreq = 4) #buscar términos más comunes en matriz
