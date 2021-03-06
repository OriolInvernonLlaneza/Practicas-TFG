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
library("wordcloud")
library("wordcloud2")
#library("RTextTools")

setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
#setwd("C:/Users/Becario-2/Desktop/RepoOri1718/practicas/Practicas-TFG/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

#ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
csv <- read.csv("cartas\\Cartas-full.csv", sep =";", header = TRUE, encoding = "UTF-8")
ex <- VCorpus(VectorSource(csv$Textodelacarta))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #numbers
  corpus <- tm_map(corpus, removePunctuation) #punt
  corpus <- tm_map(corpus, content_transformer(function(n) { n <- gsub("[��'�����*\"]", "", n)}))
  corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), customStopwords, "al")) #stopwords
  corpus <- tm_map(corpus, stripWhitespace) #extra whitespace
  #corpus <- tm_map(corpus, PlainTextDocument)  # needs to come before stemming
  return(corpus)
}

clean <- cleanCorpus(ex)
cleanCopy <- clean

source("lematizador.r")
lematizadorGPAL <- function( palabra ){
  if(palabra == "") {
    return(NA)
  }
  base.url <- paste("http://cartago.lllf.uam.es/grampal/grampal.cgi?m=analiza&e=")
  csrf <- readLines( base.url, encoding = 'utf-8' )[[59]]
  csrf <- iconv( csrf, "utf-8" )
  csrf <- strsplit(csrf, "\"")[[1]][[6]] #get csrf code
  csrf <- paste(csrf, "&e=", sep="")
  csrf <- paste(csrf, palabra, sep="")
  
  word.url <- paste(
    "http://cartago.lllf.uam.es/grampal/grampal.cgi?m=analiza&csrf=",
    csrf, sep = "")
  tmp <- readLines( word.url, encoding = 'utf-8' )

  if(length(tmp) < 79) { return(NA) }
  tmp <- iconv( tmp[[79]], "utf-8" )

  aux <- strsplit(tmp, ">")

  if(length(aux[[1]]) < 3) { return(NA) }
  tmp <- strsplit(aux[[1]][[3]], " ")[[1]][[2]]
  
  if(tmp == "-") { return(NA) }
  return(tolower(tmp))
}

checkWeirdWords <- function(w) {
  if(grepl("sierpe", w)) {
    return("sierpe")
  } else if(grepl("siervec", w)) {
    return("siervo")
  } else if(grepl("abunda", w)) {
    return("abundar")
  } else if(grepl("acepta", w)) {
    return("aceptar")
  } else if(grepl("acomod�", w)) {
    return("acomodar")
  } else if(grepl("acompa��", w)) {
    return("acompa�ar")
  } else if(grepl("acord�n", w)) {
    return("acordar")
  } else if(grepl("admira", w)) {
    return("admirar")
  } else if(grepl("ad�nd", w)) {
    return("adonde")
  } else if(grepl("advert�", w)) {
    return("advertir")
  } else if(grepl("advirt", w)) {
    return("advertir")
  } else if(grepl("afeitad", w)) {
    return("afeitar")
  } else if(grepl("agrav�", w)) {
    return("agraviar")
  } else if(grepl("agud�", w)) {
    return("agudo")
  } else if(grepl("ahorro", w)) {
    return("ahorrar")
  } else if(grepl("altern�n", w)) {
    return("alternar")
  } else if(grepl("alt�", w)) {
    return("alto")
  } else if(grepl("amabi", w)) {
    return("amable")
  } else if(grepl("anchuroso", w)) {
    return("ancho")
  } else if(grepl("animali", w)) {
    return("animal")
  } else if(grepl("anunci�n", w)) {
    return("anunciar")
  } else if(grepl("a�adi�n", w)) {
    return("a�adir")
  } else if(grepl("aparente", w)) {
    return("aparentar")
  } else if(grepl("apasionad�", w)) {
    return("apasionar")
  } else if(grepl("apologi", w)) {
    return("apolog�a")
  } else if(grepl("apoy�n", w)) {
    return("apoyar")
  } else if(grepl("ar�bi", w)) {
    return("�rabe")
  } else if(grepl("argensolas", w)) {
    return("argensola")
  } else if(grepl("armonio", w)) {
    return("armon�a")
  } else if(grepl("asegurad�", w) || grepl("asegur�", w) || grepl("aseg�", w)) {
    return("asegurar")
  } else if(grepl("atribuy�n", w)) {
    return("atribuir")
  } else if(grepl("avergonc", w) || grepl("averg�en", w)) {
    return("avergonzar")
  } else if(grepl("avis�n", w)) {
    return("avisar")
  } else if(grepl("begona", w)) {
    return("bego�a")
  } else if(grepl("bell�", w)) {
    return("bello")
  } else if(grepl("beneficio", w)) {
    return("beneficiar")
  } else if(grepl("benigni", w)) {
    return("benigno")
  } else if(grepl("brev�", w)) {
    return("breve")
  } else if(grepl("ca�", w)) {
    return("caer")
  } else if(grepl("calculi", w)) {
    return("calcular")
  } else if(grepl("cancionci", w)) {
    return("canci�n")
  } else if(grepl("canonj", w)) {
    return("can�nigo")
  } else if(grepl("cantar�", w) || grepl("cantor", w)) {
    return("cantar")
  } else if(grepl("carg�n", w)) {
    return("cargar")
  } else if(grepl("car�", w)) {
    return("caro")
  } else if(grepl("casi", w)) {
    return("casa")
  } else if(grepl("cert�", w)) {
    return("cierto")
  } else if(grepl("cesaci", w) || grepl("cesi�", w)) {
    return("cesar")
  } else if(grepl("coleg", w)) {
    return("colegio")
  } else if(grepl("colmadi", w)) {
    return("colmar")
  } else if(grepl("coloc�n", w)) {
    return("colocar")
  } else if(grepl("compara", w)) {
    return("comparar")
  } else if(grepl("comprometi�n", w)) {
    return("comprometer")
  } else if(grepl("comunic�", w)) {
    return("comunicar")
  } else if(grepl("comun�", w)) {
    return("com�n")
  } else if(grepl("concedi�", w)) {
    return("conceder")
  } else if(grepl("concu", w)) {
    return("concurrir")
  } else if(grepl("conduc", w)) {
    return("conducir")
  } else if(grepl("confes", w)) {
    return("confesar")
  } else if(grepl("confi�", w)) {
    return("confiar")
  } else if(grepl("confu", w)) {
    return("confundir")
  } else if(grepl("conos", w) || grepl("con�z", w)) {
    return("conocer")
  } else if(grepl("conserva", w)) {
    return("conservar")
  } else if(grepl("considera", w)) {
    return("considerar")
  } else if(grepl("consola", w)) {
    return("consolar")
  } else if(grepl("content�", w)) {
    return("contento")
  } else if(grepl("continu", w)) {
    return("continuar")
  } else if(grepl("conveni", w)) {
    return("convenir")
  } else if(grepl("convini�", w)) {
    return("convenir")
  } else if(grepl("cordial�", w)) {
    return("cordial")
  } else if(grepl("cortit", w)) {
    return("corto")
  } else if(grepl("costos�", w)) {
    return("costoso")
  } else if(grepl("cotej�n", w)) {
    return("cotejar")
  } else if(grepl("crecid�", w)) {
    return("crecer")
  } else if(grepl("cuarti", w)) {
    return("cuarto")
  } else if(grepl("cuid�n", w) || grepl("cu�d", w)) {
    return("cuidar")
  } else if(grepl("culebri", w)) {
    return("culebra")
  } else if(grepl("d�ndo", w) || grepl("d�rm", w)) {
    return("dar")
  } else if(grepl("deb�r", w)) {
    return("deber")
  } else if(grepl("debil", w)) {
    return("d�bil")
  } else if(grepl("defecti", w)) {
    return("defecto")
  } else if(grepl("defini�", w)) {
    return("definir")
  } else if(grepl("dej�n", w)) {
    return("dejar")
  } else if(grepl("dej�", w)) {
    return("dejar")
  } else if(grepl("delicad", w)) {
    return("delicado")
  } else if(grepl("desconsolad�", w)) {
    return("desconsolar")
  } else if(grepl("desenga��", w)) {
    return("desenga�ar")
  } else if(grepl("d�ce", w) || grepl("dici�", w) || grepl("d�g", w) || grepl("dig�", w) || grepl("d�j", w) || grepl("dir�", w)) {
    return("decir")
  } else if(grepl("dificulto", w)) {
    return("dif�cil")
  } else if(grepl("difus�", w)) {
    return("difuso")
  } else if(grepl("dilatad�", w)) {
    return("dilatar")
  } else if(grepl("dirigi�", w)) {
    return("dirigir")
  } else if(grepl("disim�", w)) {
    return("disimular")
  } else if(grepl("divi�r", w)) {
    return("divertir")
  } else if(grepl("doct�", w)) {
    return("docto")
  } else if(grepl("dulc�", w)) {
    return("dulce")
  } else if(grepl("edifi", w)) {
    return("edificar")
  } else if(grepl("eficac�", w)) {
    return("eficaz")
  } else if(grepl("ejecut", w)) {
    return("ejecutar")
  } else if(grepl("elev�n", w)) {
    return("elevar")
  } else if(grepl("eligi�", w)) {
    return("elegir")
  } else if(grepl("elocuent�", w)) {
    return("elocuente")
  } else if(grepl("encarg", w)) {
    return("encargar")
  } else if(grepl("enmoheci�", w)) {
    return("enmohecer")
  } else if(grepl("enredad�", w)) {
    return("enredar")
  } else if(grepl("enriqueci�", w)) {
    return("enriquecer")
  } else if(grepl("enter�n", w)) {
    return("entender")
  } else if(grepl("envi�", w)) {
    return("enviar")
  } else if(grepl("erarios", w)) {
    return("erario")
  } else if(grepl("escribi�", w)) {
    return("escribir")
  } else if(grepl("escritorc", w)) {
    return("escritor")
  } else if(grepl("escrupu", w)) {
    return("escr�pulo")
  } else if(grepl("especial�", w)) {
    return("especial")
  } else if(grepl("estudi", w)) {
    return("estudiar")
  } else if(grepl("extract�", w)) {
    return("extractar")
  } else if(grepl("falt�", w)) {
    return("faltar")
  } else if(grepl("felic�", w)) {
    return("feliz")
  } else if(grepl("fidel�", w)) {
    return("fiel")
  } else if(grepl("fin�", w)) {
    return("fino")
  } else if(grepl("f�r", w)) {
    return("formar")
  } else if(grepl("fuegovs", w)) {
    return("fuego")
  } else if(grepl("fundad�", w)) {
    return("fundar")
  } else if(grepl("geronimianos", w)) {
    return("geronimiano")
  } else if(grepl("gracios�", w)) {
    return("gracioso")
  } else if(grepl("grand�s", w)) {
    return("grande")
  } else if(grepl("grat�", w)) {
    return("grato")
  } else if(grepl("grav�", w)) {
    return("grave")
  } else if(grepl("gustos�", w)) {
    return("gustoso")
  } else if(grepl("hab�r", w) || grepl("habi�", w) || grepl("hubi�", w)) {
    return("haber")
  } else if(grepl("habil�", w)) {
    return("h�bil")
  } else if(grepl("habl", w)) {
    return("hablar")
  } else if(grepl("haci�", w) || grepl("hici�", w)) {
    return("hacer")
  } else if(grepl("hall�", w)) {
    return("hallar")
  } else if(grepl("hermos�", w)) {
    return("hermoso")
  } else if(grepl("humild�", w)) {
    return("humilde")
  } else if(grepl("hydr", w)) {
    return("hydro")
  } else if(grepl("incluy�n", w)) {
    return("incluir")
  } else if(grepl("individ", w)) {
    return("individual")
  } else if(grepl("industri", w)) {
    return("industrial")
  } else if(grepl("infantic", w)) {
    return("infantico")
  } else if(grepl("instruy�", w)) {
    return("instruir")
  } else if(grepl("intitul�", w)) {
    return("intitular")
  } else if(grepl("juicios�", w)) {
    return("juicioso")
  } else if(grepl("le�r", w) || grepl("le�", w)) {
    return("leer")
  } else if(grepl("lej�", w)) {
    return("lejos")
  } else if(grepl("lespagne", w)) {
    return("espa�a")
  } else if(grepl("libri", w)) {
    return("libro")
  } else if(grepl("liber", w)) {
    return("libertad")
  } else if(grepl("liger", w)) {
    return("ligero")
  } else if(grepl("ll�m", w)) {
    return("llamar")
  } else if(grepl("llev�", w)) {
    return("llevar")
  } else if(grepl("lugarc", w)) {
    return("lugar")
  } else if(grepl("mali", w) || grepl("mal�", w)) {
    return("malo")
  } else if(grepl("mand�", w)) {
    return("mandar")
  } else if(grepl("manifest�", w)) {
    return("manifestar")
  } else if(grepl("mant�", w)) {
    return("mantener")
  } else if(grepl("molest�", w)) {
    return("molesto")
  } else if(grepl("much�", w)) {
    return("mucho")
  } else if(grepl("neg�n", w)) {
    return("negar")
  } else if(grepl("nombr�n", w)) {
    return("nombrar")
  } else if(grepl("not�n", w)) {
    return("notar")
  } else if(grepl("oblig�", w)) {
    return("obligar")
  } else if(grepl("ocupad�", w)) {
    return("ocupado")
  } else if(grepl("ofrec", w)) {
    return("ofrecer")
  } else if(grepl("olvid�", w)) {
    return("olvidar")
  } else if(grepl("opon�", w)) {
    return("oponer")
  } else if(grepl("oportun�", w)) {
    return("oportuno")
  } else if(grepl("otorg�", w)) {
    return("otorgar")
  } else if(grepl("par�", w) || grepl("parec", w)) {
    return("parecer")
  } else if(grepl("pedaci", w)) {
    return("pedazo")
  } else if(grepl("pensionc", w)) {
    return("pensi�n")
  } else if(grepl("permiti�", w)) {
    return("permitir")
  } else if(grepl("pernicios�", w)) {
    return("pernicioso")
  } else if(grepl("pesad�", w)) {
    return("pesado")
  } else if(grepl("pidi�", w)) {
    return("pedir")
  } else if(grepl("pobrec", w)) {
    return("pobre")
  } else if(grepl("pod�r", w)) {
    return("poder")
  } else if(grepl("po�", w) || grepl("poet", w)) {
    return("poes�a")
  } else if(grepl("poni�", w)) {
    return("poner")
  } else if(grepl("poqu�", w)) {
    return("poco")
  } else if(grepl("precios�", w)) {
    return("precioso")
  } else if(grepl("precipitad�", w)) {
    return("precipitar")
  } else if(grepl("pregunt�", w)) {
    return("preguntar")
  } else if(grepl("previni�", w)) {
    return("prevenir")
  } else if(grepl("propon�", w)) {
    return("proponer")
  } else if(grepl("public�", w)) {
    return("publicar")
  } else if(grepl("puertec", w)) {
    return("puerto")
  } else if(grepl("pur�", w)) {
    return("puro")
  } else if(grepl("qu�d", w) || grepl("qued�", w)) {
    return("quedar")
  } else if(grepl("quej", w)) {
    return("quejar")
  } else if(grepl("recomend�", w)) {
    return("recomendar")
  } else if(grepl("refiri�", w)) {
    return("referir")
  } else if(grepl("regalad�", w)) {
    return("regalar")
  } else if(grepl("relev�n", w)) {
    return("relevar")
  } else if(grepl("remit", w)) {
    return("remitir")
  } else if(grepl("reparil", w)) {
    return("reparar")
  } else if(grepl("repetid�", w) || grepl("repiti�", w)) {
    return("repetir")
  } else if(grepl("reservad�", w) || grepl("res�rvo", w)) {
    return("reservar")
  } else if(grepl("retoc�n", w)) {
    return("retocar")
  } else if(grepl("reverend�", w)) {
    return("reverendo")
  } else if(grepl("robust�", w)) {
    return("robusto")
  } else if(grepl("sac�r", w)) {
    return("sacar")
  } else if(grepl("salad�", w)) {
    return("sal")
  } else if(grepl("sant�", w)) {
    return("santo")
  } else if(grepl("s�ame", w)) {
    return("ser")
  } else if(grepl("singular�", w)) {
    return("singular")
  } else if(grepl("sub�r", w)) {
    return("subir")
  } else if(grepl("suplic�n", w)) {
    return("suplicar")
  } else if(grepl("suponi�n", w)) {
    return("suponer")
  } else if(grepl("tant�", w)) {
    return("tanto")
  } else if(grepl("temi�", w)) {
    return("temer")
  } else if(grepl("teni�n", w)) {
    return("tener")
  } else if(grepl("tom�n", w)) {
    return("tomar")
  } else if(grepl("traduccionc", w) || grepl("traduci�", w)) {
    return("traducir")
  } else if(grepl("tra�", w)) {
    return("traer")
  } else if(grepl("trat�", w)) {
    return("tratar")
  } else if(grepl("trist�", w)) {
    return("triste")
  } else if(grepl("util�", w)) {
    return("�til")
  } else if(grepl("vali�", w)) {
    return("valer")
  } else if(grepl("v�ase", w) || grepl("ver�", w)) {
    return("ver")
  } else if(grepl("verific�n", w)) {
    return("verificar")
  } else if(grepl("verisimilitud", w)) {
    return("verosimilitud")
  } else if(grepl("viv�", w)) {
    return("vivir")
  } else if(grepl("zarzueli", w)) {
    return("zarzuela")
  } else {
    return(w)
  }
}

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
      } else {
        #print(l[[j]])
        aux <- lematizadorGPAL(l[[j]])
        if(!is.na(aux)) {
          l[[j]] <- aux
        } else {
          l[[j]] <- checkWeirdWords(l[[j]])
        }
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

#stemmed <- tm_map(stemmed, content_transformer(function(x) iconv(enc2utf8(x), sub = "byte")))
#inspect(stemmed[[40]])

dtm <- DocumentTermMatrix(stemmed) #matrix
#inspect(dtm)in
rowTotals <- apply(dtmCSV , 1, sum) #Find the sum of words in each Document
dtmCSV   <- dtmCSV[rowTotals> 0, ] #remove all docs without words
write.csv(as.matrix(dtm), "dtmFull.csv")
save(dtm, file = "dtmFull.RData")
#word list
words <- dtm$dimnames$Terms
words <- words[order(words)]
write.table(words,"wordsTotal.txt",sep="\t",row.names=FALSE)

findFreqTerms(dtm, lowfreq = 100) #buscar t�rminos m�s comunes en matriz
#sparse <- removeSparseTerms(dtm, 0.99) #remove low freq words
#mOG <- as.matrix(dtm.new)
#m <- as.matrix(sparse)

#Read DTM from file
dtmCSV <- read.csv("dtmFull.csv", header = TRUE, check.names=FALSE, row.names = 1)
#dtmCSV <- read.csv("dtmFull.csv", header = TRUE, check.names=FALSE)
#dtmF <- as.DocumentTermMatrix(dtmCSV, weighting = weightTf)
rowTotals <- apply(dtmCSV , 1, sum) #Find the sum of words in each Document
dtmCSV   <- dtmCSV[rowTotals> 0, ] #remove all docs without words
write.csv(mOG, "reee.csv")
m <- as.matrix(dtm.new)
#m2 <- m[,2:ncol(m)]
#dtmRd <- load("dtmFull.RData")

#delete verbs -> bad results
dtmPrueba$hacer <- 0
dtmPrueba$decir <- 0
dtmPrueba$poder <- 0
dtmPrueba <- dtmCSV
colTotals <- colSums(dtmPrueba)
dtmPrueba   <- dtmPrueba[, colTotals > 0]

#NbClust
library("tm") #load text mining library
library("NbClust")
setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
dtmCSV <- read.csv("dtmFull.csv", header = TRUE, check.names=FALSE, row.names = 1)
#back to dtm
dtm <- as.DocumentTermMatrix(dtmCSV, weighting = weightTf)
sparse <- removeSparseTerms(dtm, 0.995)
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
        min.nc = 3, max.nc = 14, method = "kmeans", index = "silhouette")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
        min.nc = 3, max.nc = 14, method = "kmeans", index = "hubert")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
        min.nc = 2, max.nc = 14, method = "kmeans", index = "ball")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
        min.nc = 2, max.nc = 14, method = "kmeans", index = "dindex")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "dunn")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "sdindex")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "gamma")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "hartigan")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "duda")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "marriot")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "rubin")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "pseudot2")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "beale")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "frey")
kmNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "kmeans", index = "gap")

avNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 3, max.nc = 14, method = "average", index = "silhouette")
avNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "average", index = "pseudot2")
avNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "average", index = "ball")
avNC2 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "average", index = "frey")
avNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "average", index = "cindex")

siNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "single", index = "silhouette")
siNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "single", index = "pseudot2")
siNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "single", index = "ball")
siNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "single", index = "frey")
siNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "single", index = "cindex")

comNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "complete", index = "silhouette")
comNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "complete", index = "pseudot2")
comC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "complete", index = "ball")
comC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "complete", index = "frey")
comC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "complete", index = "cindex")

cenC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                  min.nc = 2, max.nc = 14, method = "centroid", index = "silhouette")
cenC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                  min.nc = 2, max.nc = 14, method = "centroid", index = "pseudot2")
cenC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "centroid", index = "ball")
cenC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "centroid", index = "frey")
cenC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "centroid", index = "cindex")

warNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                  min.nc = 2, max.nc = 14, method = "ward.D", index = "silhouette")
warNC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                  min.nc = 2, max.nc = 14, method = "ward.D", index = "pseudot2")
warC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "ward.D", index = "ball")
warC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "ward.D", index = "frey")
warC1 <- NbClust(data = sparse, diss = NULL, distance = "euclidean", 
                 min.nc = 2, max.nc = 14, method = "ward.D", index = "cindex")

#k means algorithm 1
d <- dist(m)
fviz_nbclust(m, kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
kfit <- kmeans(sparse, 3, nstart=100)
plot(prcomp(sparse)$x, col=kfit$cl)
fviz_cluster(kfit, sparse, ellipse = FALSE, geom = "point")
sil.kfit <- silhouette(kfit$cluster, prcomp(sparse)$x)
#clusplot(m, kfit$cluster, color=T, shade=T, labels=2, lines=0)
kfitm <- kmeans(m, 9, nstart=100)
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
h1 <- agnes(sparse, metric = "euclidean", stand = FALSE)
h2 <- diana(sparse, metric = "euclidean", stand = FALSE)

pdf("agnes1Aver.pdf", width=60, height=15)
pltree(h1, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
dev.off()

pdf("diana1.pdf", width=60, height=15)
pltree(h2, cex = 0.6, hang = -1, main = "Dendrograma de diana")
dev.off()

h12 <- agnes(sparse, method = "ward", metric = "euclidean", stand = FALSE)

pdf("agnes2Ward.pdf", width=60, height=15)
pltree(h12, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
dev.off()
ward.cut <- cutree(h12, k=2)
sil.ward <- silhouette(ward.cut, dist(sparse))
wsum <- summary(sil.ward)
wsum$clus.avg.widths
wsum$clus.sizes
wsum$avg.width

tdmCSV <- t(dtmCSV)
tdm <- as.TermDocumentMatrix(tdmCSV, weighting = weightTf)
tdmSp <- removeSparseTerms(tdm, 0.995)
library("clValid")
clres <- clValid(obj = as.matrix(tdm), nClust = 3:9, clMethods = "agnes",
        validation = "internal",
        metric = "euclidean", method = "ward")

h13 <- agnes(sparse, method = "single", metric = "euclidean", stand = FALSE)

pdf("agnesSingle.pdf", width=60, height=15)
pltree(h13, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
dev.off()

h14 <- agnes(sparse, method = "complete", metric = "euclidean", stand = FALSE)

pdf("agnesComplete.pdf", width=60, height=15)
pltree(h14, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
dev.off()


##################

#density
kNNdistplot(sparse, k = 10)
abline(h = 30, lty = 2)
db <- dbscan(m, 9, 3)
fviz_cluster(db, data = m, stand = FALSE,
             ellipse = TRUE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())
kNNdistplot(m, k = 3)
abline(h = 25, lty = 2)
db <- dbscan(m, 25, 3)
fviz_cluster(db, data = m, stand = FALSE,
             ellipse = TRUE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())
tfxidf <- weightTfIdf(dtm, normalize = TRUE)
kNNdistplot(tfxidf, k = 20)
abline(h = 1.4, lty = 2)
db <- dbscan(tfxidf, 1.4, 20)
fviz_cluster(db, data = as.matrix(tfxidf), stand = FALSE,
             ellipse = FALSE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())

#hdbscann
hdb <- hdbscan(m, 3)
plot(m, col=hdb$cluster+1L, cex = .5)
plot(hdb)
plot(hdb$hc, main="HDBSCAN* Hierarchy")


#Topic modeling
#Set parameters for Gibbs sampling
burnin <- 4000
iter <- 1500
thin <- 50
seed <-list(2003,5,63,100001,765)
nstart <- 5
best <- TRUE
#Number of topics
k <- 7
ldaOut <-LDA(dtmCSV, k, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))
ldaOut5 <-LDA(dtm.new, 5, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))
ldaOut6 <-LDA(dtm.new, 6, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))
ldaOut9 <-LDA(dtm.new, 9, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))

#docs to topics
ldaOut.topics <- as.matrix(topics(ldaOut))
write.csv(ldaOut.topics,file=paste("TopicModel/LDAGibbsSparse",k,"V2DocsToTopics.csv"))

#top 25 terms by topic
ldaOut.terms <- as.matrix(terms(ldaOut,25))
write.csv(ldaOut.terms,file=paste("TopicModel/LDAGibbsSparse",k,"V2TopicsToTerms.csv"))

#probabilities
topicProbabilities <- as.data.frame(ldaOut@gamma)
write.csv(topicProbabilities,file=paste("TopicModel/LDAGibbsSparse",k,"V2TopicProbabilities.csv"))

jo_topics <- tidy(ldaOut, matrix = "beta")
library(ggplot2)
library(dplyr)

ap_top_terms <- jo_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()

#worldclouds
topic <- 7
dfTopic <- data.frame(terms = ldaOut@terms, p = exp(ldaOut@beta[topic,]))
head(dfTopic[order(-dfTopic$p),])
wordcloud(words = dfTopic$terms,
          freq = dfTopic$p,
          max.words = 100,
          random.order = FALSE,
          rot.per = 0.35,
          colors=brewer.pal(8, "Dark2"))

ap_top_terms <- jo_topics %>%
  group_by(topic) %>%
  top_n(12, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)
ap_top_terms %>%
  mutate(topic = paste("topic", topic)) %>%
  acast(term ~ topic, value.var = "beta", fill = 0) %>%
  comparison.cloud(colors = c("#F8766D", "#00BFC4", "#7a8dba",
                              "#d78dba", "#bdffba", "#4f87ff", "#f4f49c"), max.words = 100)

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
