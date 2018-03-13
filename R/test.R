library("NLP")
library("tm") #load text mining library
library("SnowballC")
library("RColorBrewer")
library("wordcloud")

setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
summary(ex)  #check what went in

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

ex <- tm_map(ex, content_transformer(tolower)) #a minus
ex <- tm_map(ex, PlainTextDocument)
ex <- tm_map(ex, removeNumbers) #números
ex <- tm_map(ex, removePunctuation) #puntuación
ex <- tm_map(ex, removeWords, c(stopwords("spanish"), customStopwords)) #Borrar palabras vacías.
ex <- tm_map(ex, stripWhitespace) #espacios en blanco extras
wordStem(ex[[1]], language="spanish")

inspect(ex[[1]])

matrix <-DocumentTermMatrix(ex) #matriz
findFreqTerms(matrix, lowfreq = 4) #buscar términos más comunes en matriz
