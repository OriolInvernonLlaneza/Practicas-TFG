library("NLP")
library("tm") #load text mining library
ex  <- VCorpus(DirSource("cartas\\ejemplo"), readerControl = list(language="es"))
summary(ex)  #check what went in
ex <- tm_map(ex, removeNumbers)
ex <- tm_map(ex, removePunctuation)
ex <- tm_map(ex , stripWhitespace)
ex <- tm_map(ex, content_transformer(tolower))
ex <- tm_map(ex, removeWords, stopwords("spanish")) 
ex <- tm_map(ex, stemDocument, language = "spanish")
matrix <-DocumentTermMatrix(ex) 
