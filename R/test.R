library("NLP")
library("tm") #load text mining library
library("fastmatch")
library("XML")
library("stringr")
#library("RColorBrewer")
#library("wordcloud2")
#library("RTextTools")

#setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

#ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
csv <- read.csv("cartas\\CorrespondenciaJove.csv", sep =";", header = TRUE, encoding = "UTF-8")
ex <- VCorpus(VectorSource(csv$TextoCarta[1:50]))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #números
  corpus <- tm_map(corpus, removePunctuation) #puntuación
  corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), customStopwords)) #Borrar palabras vacías.
  corpus <- tm_map(corpus, stripWhitespace) #espacios en blanco extras
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

matrix <- DocumentTermMatrix(stemmed) #matriz
findFreqTerms(matrix, lowfreq = 30) #buscar términos más comunes en matriz