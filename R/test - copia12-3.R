library("NLP")
library("tm") #load text mining library
library("SnowballC")
library("RColorBrewer")
library("wordcloud")

#setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
summary(ex)  #check what went in

ex <- tm_map(ex, content_transformer(tolower)) #a minus
ex <- tm_map(ex, PlainTextDocument)
ex <- tm_map(ex, removeNumbers) #números
ex <- tm_map(ex, removePunctuation) #puntuación
ex <- tm_map(ex, stripWhitespace) #espacios en blanco extras
ex <- tm_map(ex, removeWords, c(stopwords("spanish"), "gaspar", "melchor", "jovellanos", "servidor", "VSI")) #Borrar palabras vacías.
ex <- tm_map(ex, stemDocument) 

inspect(ex[[1]])

matrix <-DocumentTermMatrix(ex) #matriz
findFreqTerms(matrix, lowfreq = 2) #buscar términos más comunes en matriz

sparse <- removeSparseTerms(matrix, 0.5) #eliminar menos frecuentes

m <- as.matrix(matrix) #treat dtm as amtrix
v <- sort(rowSums(m), decreasing=TRUE) #ordenarla por frecuencia
d <- data.frame(word = names(v), freq = v)

head(d, 10)
set.seed(1234)
#wordcloud(words = d$word, freq = d$freq, min.freq = 1, max.words=200, random.order=FALSE, rot.per=0.35, colors=brewer.pal(8, "Dark2"))

findAssocs(matrix, terms = "señor", corlimit = 0.3) #buscar términos que van juntos

barplot(d[1:10,]$freq, las = 2, names.arg = d[1:10,]$word,
        col ="lightblue", main ="Most frequent words",
        ylab = "Word frequencies")
