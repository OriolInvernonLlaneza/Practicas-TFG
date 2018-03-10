library("NLP")
library("tm") #load text mining library
library("SnowballC")
library("RColorBrewer")
library("wordcloud")
#setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
summary(ex)  #check what went in
ex <- tm_map(ex, removeNumbers) #números
ex <- tm_map(ex, removePunctuation) #puntuación
#ex <- tm_map(ex, stripWhitespace) #espacios en blanco extras
ex <- tm_map(ex, stemDocument, language = "spanish") #Sacar raíces
ex <- tm_map(ex, content_transformer(tolower)) #a minus
ex <- tm_map(ex, removeWords, stopwords("spanish")) #Borrar palabras vacías.
ex <- tm_map(ex, removeWords, c("ejemplo1", "ejemplo2")) #Borrar palabras custom
inspect(ex[[1]])
wordcloud(ex, max.words = 200, random.order = FALSE)
matrix <-DocumentTermMatrix(ex) #matriz
m <- as.matrix(matrix) #treat dtm as amtrix
v <- sort(rowSums(m), decreasing=TRUE) #ordenarla por frecuencia
d <- data.frame(word = names(v), freq = v)
head(d, 10)
set.seed(1234)
#wordcloud(words = d$word, freq = d$freq, min.freq = 1, max.words=200, random.order=FALSE, rot.per=0.35, colors=brewer.pal(8, "Dark2"))
findFreqTerms(matrix, lowfreq = 4) #buscar términos más comunes en matriz
findAssocs(matrix, terms = "señor", corlimit = 0.3) #buscar términos que van juntos
barplot(d[1:10,]$freq, las = 2, names.arg = d[1:10,]$word,
        col ="lightblue", main ="Most frequent words",
        ylab = "Word frequencies")
