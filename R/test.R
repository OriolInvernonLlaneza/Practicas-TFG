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

#setwd("D:/Users/Oriol/Documents/practicas/proyecto/R")
setwd("C:/Users/Becario-2/Desktop/RepoOri1718/practicas/Practicas-TFG/R")

customStopwords <- read.table("stopwordsJovellanos.txt", header = TRUE)
customStopwords <- as.vector(customStopwords$WORDS)

#ex  <- VCorpus(DirSource(directory = "cartas\\ejemplo", encoding = "UTF-8"), readerControl = list(language="es"))
csv <- read.csv("cartas\\Cartas-full.csv", sep =";", header = TRUE, encoding = "UTF-8")
ex <- VCorpus(VectorSource(csv$Textodelacarta))

cleanCorpus <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(tolower)) #a minus
  corpus <- tm_map(corpus, removeNumbers) #numbers
  corpus <- tm_map(corpus, removePunctuation) #punt
  corpus <- tm_map(corpus, content_transformer(function(n) { n <- gsub("[¡¿'«»ªº°*\"]", "", n)}))
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
  } else if(grepl("acomodá", w)) {
    return("acomodar")
  } else if(grepl("acompañá", w)) {
    return("acompañar")
  } else if(grepl("acordán", w)) {
    return("acordar")
  } else if(grepl("admira", w)) {
    return("admirar")
  } else if(grepl("adónd", w)) {
    return("adonde")
  } else if(grepl("advertí", w)) {
    return("advertir")
  } else if(grepl("advirt", w)) {
    return("advertir")
  } else if(grepl("afeitad", w)) {
    return("afeitar")
  } else if(grepl("agravá", w)) {
    return("agraviar")
  } else if(grepl("agudí", w)) {
    return("agudo")
  } else if(grepl("ahorro", w)) {
    return("ahorrar")
  } else if(grepl("alternán", w)) {
    return("alternar")
  } else if(grepl("altí", w)) {
    return("alto")
  } else if(grepl("amabi", w)) {
    return("amable")
  } else if(grepl("anchuroso", w)) {
    return("ancho")
  } else if(grepl("animali", w)) {
    return("animal")
  } else if(grepl("anuncián", w)) {
    return("anunciar")
  } else if(grepl("añadién", w)) {
    return("añadir")
  } else if(grepl("aparente", w)) {
    return("aparentar")
  } else if(grepl("apasionadí", w)) {
    return("apasionar")
  } else if(grepl("apologi", w)) {
    return("apología")
  } else if(grepl("apoyán", w)) {
    return("apoyar")
  } else if(grepl("arábi", w)) {
    return("árabe")
  } else if(grepl("argensolas", w)) {
    return("argensola")
  } else if(grepl("armonio", w)) {
    return("armonía")
  } else if(grepl("aseguradí", w) || grepl("asegurá", w) || grepl("asegú", w)) {
    return("asegurar")
  } else if(grepl("atribuyén", w)) {
    return("atribuir")
  } else if(grepl("avergonc", w) || grepl("avergüen", w)) {
    return("avergonzar")
  } else if(grepl("avisán", w)) {
    return("avisar")
  } else if(grepl("begona", w)) {
    return("begoña")
  } else if(grepl("bellí", w)) {
    return("bello")
  } else if(grepl("beneficio", w)) {
    return("beneficiar")
  } else if(grepl("benigni", w)) {
    return("benigno")
  } else if(grepl("breví", w)) {
    return("breve")
  } else if(grepl("caí", w)) {
    return("caer")
  } else if(grepl("calculi", w)) {
    return("calcular")
  } else if(grepl("cancionci", w)) {
    return("canción")
  } else if(grepl("canonj", w)) {
    return("canónigo")
  } else if(grepl("cantarí", w) || grepl("cantor", w)) {
    return("cantar")
  } else if(grepl("cargán", w)) {
    return("cargar")
  } else if(grepl("carí", w)) {
    return("caro")
  } else if(grepl("casi", w)) {
    return("casa")
  } else if(grepl("certí", w)) {
    return("cierto")
  } else if(grepl("cesaci", w) || grepl("cesió", w)) {
    return("cesar")
  } else if(grepl("coleg", w)) {
    return("colegio")
  } else if(grepl("colmadi", w)) {
    return("colmar")
  } else if(grepl("colocán", w)) {
    return("colocar")
  } else if(grepl("compara", w)) {
    return("comparar")
  } else if(grepl("comprometién", w)) {
    return("comprometer")
  } else if(grepl("comunicá", w)) {
    return("comunicar")
  } else if(grepl("comuní", w)) {
    return("común")
  } else if(grepl("concedié", w)) {
    return("conceder")
  } else if(grepl("concu", w)) {
    return("concurrir")
  } else if(grepl("conduc", w)) {
    return("conducir")
  } else if(grepl("confes", w)) {
    return("confesar")
  } else if(grepl("confié", w)) {
    return("confiar")
  } else if(grepl("confu", w)) {
    return("confundir")
  } else if(grepl("conos", w) || grepl("conóz", w)) {
    return("conocer")
  } else if(grepl("conserva", w)) {
    return("conservar")
  } else if(grepl("considera", w)) {
    return("considerar")
  } else if(grepl("consola", w)) {
    return("consolar")
  } else if(grepl("contentí", w)) {
    return("contento")
  } else if(grepl("continu", w)) {
    return("continuar")
  } else if(grepl("conveni", w)) {
    return("convenir")
  } else if(grepl("convinié", w)) {
    return("convenir")
  } else if(grepl("cordialí", w)) {
    return("cordial")
  } else if(grepl("cortit", w)) {
    return("corto")
  } else if(grepl("costosí", w)) {
    return("costoso")
  } else if(grepl("coteján", w)) {
    return("cotejar")
  } else if(grepl("crecidí", w)) {
    return("crecer")
  } else if(grepl("cuarti", w)) {
    return("cuarto")
  } else if(grepl("cuidán", w) || grepl("cuíd", w)) {
    return("cuidar")
  } else if(grepl("culebri", w)) {
    return("culebra")
  } else if(grepl("dándo", w) || grepl("dárm", w)) {
    return("dar")
  } else if(grepl("debér", w)) {
    return("deber")
  } else if(grepl("debil", w)) {
    return("débil")
  } else if(grepl("defecti", w)) {
    return("defecto")
  } else if(grepl("definié", w)) {
    return("definir")
  } else if(grepl("deján", w)) {
    return("dejar")
  } else if(grepl("dejé", w)) {
    return("dejar")
  } else if(grepl("delicad", w)) {
    return("delicado")
  } else if(grepl("desconsoladí", w)) {
    return("desconsolar")
  } else if(grepl("desengañé", w)) {
    return("desengañar")
  } else if(grepl("díce", w) || grepl("dicié", w) || grepl("díg", w) || grepl("digá", w) || grepl("díj", w) || grepl("diré", w)) {
    return("decir")
  } else if(grepl("dificulto", w)) {
    return("difícil")
  } else if(grepl("difusí", w)) {
    return("difuso")
  } else if(grepl("dilatadí", w)) {
    return("dilatar")
  } else if(grepl("dirigié", w)) {
    return("dirigir")
  } else if(grepl("disimú", w)) {
    return("disimular")
  } else if(grepl("diviér", w)) {
    return("divertir")
  } else if(grepl("doctí", w)) {
    return("docto")
  } else if(grepl("dulcí", w)) {
    return("dulce")
  } else if(grepl("edifi", w)) {
    return("edificar")
  } else if(grepl("eficací", w)) {
    return("eficaz")
  } else if(grepl("ejecut", w)) {
    return("ejecutar")
  } else if(grepl("eleván", w)) {
    return("elevar")
  } else if(grepl("eligié", w)) {
    return("elegir")
  } else if(grepl("elocuentí", w)) {
    return("elocuente")
  } else if(grepl("encarg", w)) {
    return("encargar")
  } else if(grepl("enmohecié", w)) {
    return("enmohecer")
  } else if(grepl("enredadí", w)) {
    return("enredar")
  } else if(grepl("enriquecié", w)) {
    return("enriquecer")
  } else if(grepl("enterán", w)) {
    return("entender")
  } else if(grepl("enviá", w)) {
    return("enviar")
  } else if(grepl("erarios", w)) {
    return("erario")
  } else if(grepl("escribié", w)) {
    return("escribir")
  } else if(grepl("escritorc", w)) {
    return("escritor")
  } else if(grepl("escrupu", w)) {
    return("escrúpulo")
  } else if(grepl("especialí", w)) {
    return("especial")
  } else if(grepl("estudi", w)) {
    return("estudiar")
  } else if(grepl("extractá", w)) {
    return("extractar")
  } else if(grepl("faltá", w)) {
    return("faltar")
  } else if(grepl("felicí", w)) {
    return("feliz")
  } else if(grepl("fidelí", w)) {
    return("fiel")
  } else if(grepl("finí", w)) {
    return("fino")
  } else if(grepl("fór", w)) {
    return("formar")
  } else if(grepl("fuegovs", w)) {
    return("fuego")
  } else if(grepl("fundadí", w)) {
    return("fundar")
  } else if(grepl("geronimianos", w)) {
    return("geronimiano")
  } else if(grepl("graciosí", w)) {
    return("gracioso")
  } else if(grepl("grandís", w)) {
    return("grande")
  } else if(grepl("gratí", w)) {
    return("grato")
  } else if(grepl("graví", w)) {
    return("grave")
  } else if(grepl("gustosí", w)) {
    return("gustoso")
  } else if(grepl("habér", w) || grepl("habié", w) || grepl("hubié", w)) {
    return("haber")
  } else if(grepl("habilí", w)) {
    return("hábil")
  } else if(grepl("habl", w)) {
    return("hablar")
  } else if(grepl("hacié", w) || grepl("hicié", w)) {
    return("hacer")
  } else if(grepl("hallá", w)) {
    return("hallar")
  } else if(grepl("hermosí", w)) {
    return("hermoso")
  } else if(grepl("humildí", w)) {
    return("humilde")
  } else if(grepl("hydr", w)) {
    return("hydro")
  } else if(grepl("incluyén", w)) {
    return("incluir")
  } else if(grepl("individ", w)) {
    return("individual")
  } else if(grepl("industri", w)) {
    return("industrial")
  } else if(grepl("infantic", w)) {
    return("infantico")
  } else if(grepl("instruyé", w)) {
    return("instruir")
  } else if(grepl("intitulá", w)) {
    return("intitular")
  } else if(grepl("juiciosí", w)) {
    return("juicioso")
  } else if(grepl("leér", w) || grepl("leí", w)) {
    return("leer")
  } else if(grepl("lejí", w)) {
    return("lejos")
  } else if(grepl("lespagne", w)) {
    return("españa")
  } else if(grepl("libri", w)) {
    return("libro")
  } else if(grepl("liber", w)) {
    return("libertad")
  } else if(grepl("liger", w)) {
    return("ligero")
  } else if(grepl("llám", w)) {
    return("llamar")
  } else if(grepl("llevá", w)) {
    return("llevar")
  } else if(grepl("lugarc", w)) {
    return("lugar")
  } else if(grepl("mali", w) || grepl("malí", w)) {
    return("malo")
  } else if(grepl("mandó", w)) {
    return("mandar")
  } else if(grepl("manifestá", w)) {
    return("manifestar")
  } else if(grepl("manté", w)) {
    return("mantener")
  } else if(grepl("molestí", w)) {
    return("molesto")
  } else if(grepl("muchí", w)) {
    return("mucho")
  } else if(grepl("negán", w)) {
    return("negar")
  } else if(grepl("nombrán", w)) {
    return("nombrar")
  } else if(grepl("notán", w)) {
    return("notar")
  } else if(grepl("obligá", w)) {
    return("obligar")
  } else if(grepl("ocupadí", w)) {
    return("ocupado")
  } else if(grepl("ofrec", w)) {
    return("ofrecer")
  } else if(grepl("olvidá", w)) {
    return("olvidar")
  } else if(grepl("oponé", w)) {
    return("oponer")
  } else if(grepl("oportuní", w)) {
    return("oportuno")
  } else if(grepl("otorgá", w)) {
    return("otorgar")
  } else if(grepl("paré", w) || grepl("parec", w)) {
    return("parecer")
  } else if(grepl("pedaci", w)) {
    return("pedazo")
  } else if(grepl("pensionc", w)) {
    return("pensión")
  } else if(grepl("permitié", w)) {
    return("permitir")
  } else if(grepl("perniciosí", w)) {
    return("pernicioso")
  } else if(grepl("pesadí", w)) {
    return("pesado")
  } else if(grepl("pidié", w)) {
    return("pedir")
  } else if(grepl("pobrec", w)) {
    return("pobre")
  } else if(grepl("podér", w)) {
    return("poder")
  } else if(grepl("poé", w) || grepl("poet", w)) {
    return("poesía")
  } else if(grepl("ponié", w)) {
    return("poner")
  } else if(grepl("poquí", w)) {
    return("poco")
  } else if(grepl("preciosí", w)) {
    return("precioso")
  } else if(grepl("precipitadí", w)) {
    return("precipitar")
  } else if(grepl("pregunté", w)) {
    return("preguntar")
  } else if(grepl("previnié", w)) {
    return("prevenir")
  } else if(grepl("proponí", w)) {
    return("proponer")
  } else if(grepl("publicá", w)) {
    return("publicar")
  } else if(grepl("puertec", w)) {
    return("puerto")
  } else if(grepl("purí", w)) {
    return("puro")
  } else if(grepl("quéd", w) || grepl("quedó", w)) {
    return("quedar")
  } else if(grepl("quej", w)) {
    return("quejar")
  } else if(grepl("recomendá", w)) {
    return("recomendar")
  } else if(grepl("refirié", w)) {
    return("referir")
  } else if(grepl("regaladí", w)) {
    return("regalar")
  } else if(grepl("releván", w)) {
    return("relevar")
  } else if(grepl("remit", w)) {
    return("remitir")
  } else if(grepl("reparil", w)) {
    return("reparar")
  } else if(grepl("repetidí", w) || grepl("repitié", w)) {
    return("repetir")
  } else if(grepl("reservadí", w) || grepl("resérvo", w)) {
    return("reservar")
  } else if(grepl("retocán", w)) {
    return("retocar")
  } else if(grepl("reverendí", w)) {
    return("reverendo")
  } else if(grepl("robustí", w)) {
    return("robusto")
  } else if(grepl("sacár", w)) {
    return("sacar")
  } else if(grepl("saladí", w)) {
    return("sal")
  } else if(grepl("santí", w)) {
    return("santo")
  } else if(grepl("séame", w)) {
    return("ser")
  } else if(grepl("singularí", w)) {
    return("singular")
  } else if(grepl("subír", w)) {
    return("subir")
  } else if(grepl("suplicán", w)) {
    return("suplicar")
  } else if(grepl("suponién", w)) {
    return("suponer")
  } else if(grepl("tantí", w)) {
    return("tanto")
  } else if(grepl("temié", w)) {
    return("temer")
  } else if(grepl("tenién", w)) {
    return("tener")
  } else if(grepl("tomán", w)) {
    return("tomar")
  } else if(grepl("traduccionc", w) || grepl("traducié", w)) {
    return("traducir")
  } else if(grepl("traí", w)) {
    return("traer")
  } else if(grepl("tratá", w)) {
    return("tratar")
  } else if(grepl("tristí", w)) {
    return("triste")
  } else if(grepl("utilí", w)) {
    return("útil")
  } else if(grepl("valié", w)) {
    return("valer")
  } else if(grepl("véase", w) || grepl("verá", w)) {
    return("ver")
  } else if(grepl("verificán", w)) {
    return("verificar")
  } else if(grepl("verisimilitud", w)) {
    return("verosimilitud")
  } else if(grepl("viví", w)) {
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
write.csv(as.matrix(dtm), "dtmTotal.csv")
save("dtm", file = "dtmFull.RData", list=list("dtm"))
#word list
words <- dtm$dimnames$Terms
words <- words[order(words)]
write.table(words,"wordsTotal.txt",sep="\t",row.names=FALSE)

findFreqTerms(dtm, lowfreq = 100) #buscar términos más comunes en matriz
sparse <- removeSparseTerms(dtm, 0.99) #remove low freq words
mOG <- as.matrix(dtm)
m <- as.matrix(sparse)

dtmCSV <- read.csv("dtmTotal.csv", header = TRUE)
dtmF <- as.DocumentTermMatrix(dtmCSV, weighting = weightTf)
dtmF <- load("dtmFull.RData")

#k means algorithm 1
d <- dist(m)
fviz_nbclust(as.matrix(d), kmeans, method = "wss", k.max = 25) #elbow check
set.seed(1917)
kfit <- kmeans(d, 4, nstart=100)
plot(prcomp(d)$x, col=kfit$cl)
fviz_cluster(kfit, d, ellipse = FALSE, geom = "point")
#clusplot(m, kfit$cluster, color=T, shade=T, labels=2, lines=0)
kfitm <- kmeans(mOG, 7, nstart=100)
fviz_cluster(kfitm, mOG, ellipse = FALSE, geom = "point")

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

h11 <- agnes(mOG, stand = FALSE)
h22 <- diana(mOG, stand = FALSE)
pltree(h11, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h22, cex = 0.6, hang = -1, main = "Dendrograma de diana")

h111 <- agnes(d, metric = "euclidean", stand = FALSE)
h222 <- diana(d, metric = "euclidean", stand = FALSE)
pltree(h111, cex = 0.6, hang = -1, main = "Dendrograma de agnes")
pltree(h222, cex = 0.6, hang = -1, main = "Dendrograma de diana")

#density
kNNdistplot(mOG, k = 3)
abline(h = 30, lty = 2)
db <- dbscan(mOG, 35, 3)
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
kNNdistplot(tfxidf, k = 20)
abline(h = 1.4, lty = 2)
db <- dbscan(tfxidf, 1.4, 20)
fviz_cluster(db, data = as.matrix(tfxidf), stand = FALSE,
             ellipse = FALSE, show.clust.cent = FALSE,
             geom = "point",palette = "jco", ggtheme = theme_classic())

#hdbscann
hdb <- hdbscan(mOG, 3)
plot(mOG, col=hdb$cluster+1L, cex = .5)
plot(hdb)
plot(hdb$hc, main="HDBSCAN* Hierarchy")

#----------------5-fold cross-validation, different numbers of topics----------------
# set up a cluster for parallel processing
cluster <- makeCluster(detectCores(logical = TRUE) - 1) # leave one CPU spare...
registerDoParallel(cluster)

# load up the needed R package on all the parallel sessions
clusterEvalQ(cluster, {
  library(topicmodels)
})

full_data <- dtm
n <- nrow(full_data)
burnin <- 4000
iter <- 1500
keep <- 50
folds <- 5
splitfolds <- sample(1:folds, n, replace = TRUE)
candidate_k <- c(3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 23, 25, 30) # candidates for how many topics

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
#Number of topics
k <- 10
ldaOut <-LDA(mOG, k, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))
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
  top_n(10, beta) %>%
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
