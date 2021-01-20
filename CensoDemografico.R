require(RSQLite)
require(data.table)
require(survey)
library(DBI)
library(curl)
library(hash)
library(readxl)

microdados_censo <- function(uf){
  #criando environment com para relacionar o codigo da uf com a uf
  h <- hash()
  h[['RO']] <- 11
  h[['AC']] <- 12
  h[['AM']] <- 13
  h[['RR']] <- 14
  h[['PA']] <- 15
  h[['AP']] <- 16
  h[['TO']] <- 17
  h[['MA']] <- 21
  h[['PI']] <- 22
  h[['CE']] <- 23
  h[['RN']] <- 24
  h[['PB']] <- 25
  h[['PE']] <- 26
  h[['AL']] <- 27
  h[['SE']] <- 28
  h[['BA']] <- 29
  h[['MG']] <- 31
  h[['ES']] <- 32
  h[['RJ']] <- 33
  h[['SP']] <- 35
  h[['PR']] <- 41
  h[['SC']] <- 42
  h[['RS']] <- 43
  h[['MT']] <- 51
  h[['GO']] <- 52
  h[['DF']] <- 53
  h[['MS']] <- 50
  
  #url para download dos dados
  url = paste0('https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/',uf,'.zip')
  
  #arquivos temporarios
  temp <- tempfile()
  temp2 <- tempfile()
  
  #baixando e deszipando
  download.file(url, temp, mode = "wb")
  unzip(zipfile = temp, exdir = temp2)
  
  #criando o arquivo para armazenamento das informacoes
  con <- dbConnect(RSQLite::SQLite(), dbname = "AMOSTRA")
  dbWriteTable(conn = con, name = "PESSOAS", value = file.path(temp2, paste0(uf,"/Amostra_Pessoas_",h[[uf]],".txt")), header = FALSE, row.names = FALSE, overwrite = TRUE, eol = '\n') 
  
  return(con)
  
}


# baixando e tratando a documentação
url = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/Documentacao.zip'
temp <- tempfile()
temp2 <- tempfile()
download.file(url, temp, mode = "wb")
unzip(zipfile = temp, exdir = temp2)
doc <- read_excel(file.path(temp2, paste0("/Documenta‡Æo/Layout/Layout_microdados_Amostra.xls")))
colnames(doc)<-doc[1,]
doc<-doc[-1,]

#selecionando as UFs desejadas
uf<-c('AL','SE')

#criando df para armazenar os dados
df<-data.frame()

#looping para pegar as ufs
for (i in uf){

con <- microdados_censo(i)

#selecao dos dados desejados - olhar na documentacao, se coloca: substr(V1,posicao inciail, int+dec) `Cod Variável`
dados <- data.table(dbGetQuery(con, "select substr(V1, 29, 16) `V0010`, substr(V1, 8, 13) `V0011`, substr(V1, 21, 8) `V0300`, substr(V1, 154, 2) `V0633`, substr(V1, 158, 1) `V6400`, substr(V1, 3, 5) `V0002`, substr(V1,62,3) `V6036` from PESSOAS"))

#coluna para marcar a UF
dados$uf<-i

#Unindo as ufs
df<-rbind(df,dados)

#excluindo dados
rm (dados)

}

#tratando os dados para criar o plano amostral
df[, V0010 := as.double(V0010) / 10 ^ 13]

df[, FPC:=sum(V0010), by = V0011]

#tratando os outros dados desejados, essa parte e necessaria para trabalhar no plano amostral com o pacote survey
#variaveis categoricas precisam ser transformadas em fator

df[, V0633 := factor(V0633, levels=sprintf('%02d', 1:14), labels=c("Creche, pré-escolar (maternal e jardim de infância), classe de alfabetização - CA", "Alfabetização de jovens e adultos", "Antigo primário (elementar)", "Antigo ginásio (médio 1º ciclo)", "Ensino fundamental ou 1º grau (da 1ª a 3ª série/ do 1º ao 4º ano)", "Ensino fundamental ou 1º grau (4ª série/ 5º ano)", "Ensino fundamental ou 1º grau (da 5ª a 8ª série/ 6º ao 9º ano)", "Supletivo do ensino fundamental ou do 1º grau", "Antigo científico, clássico, etc.....(médio 2º ciclo)", "Regular ou supletivo do ensino médio ou do 2º grau", "Superior de graduação", "Especialização de nível superior ( mínimo de 360 horas )", "Mestrado", "Doutorado"))] # Lembre que aqui os valores possuem dois digitos, portanto os valores são 01, 02, ... 13, 14 e nao 1, 2, ..., 13, 14.

df[, V6400 := factor(V6400, levels=1:5, labels=c('Sem instrução e fundamental incompleto ', 'Fundamental completo e médio incompleto ','Médio completo e superior incompleto ','Superior completo ','Não determinado '))]

df[, V6036 := as.numeric(V6036)]


#amostra - deve ser feita depois de todo o tratamento da base
amostra <- svydesign(ids = ~ V0300,  strata = ~ V0011, weights = ~ V0010, fpc = ~ FPC, data = df)

#subamostras para analises desejadas - exemplo

anos18_fund<-subset(amostra,uf=="AL"&V6036>=18&V0633=="Antigo primário (elementar)"|
                      uf=="AL"&V6036>=18&V0633=="Ensino fundamental ou 1º grau (da 1ª a 3ª série/ do 1º ao 4º ano)"|
                      uf=="AL"&V6036>=18&V0633=="Ensino fundamental ou 1º grau (4ª série/ 5º ano)"|
                      uf=="AL"&V6036>=18&V0633=="Ensino fundamental ou 1º grau (da 5ª a 8ª série/ 6º ao 9º ano)"|
                      uf=="AL"&V6036>=18&V0633=="Supletivo do ensino fundamental ou do 1º grau")


df<-as.data.frame(svyby(~ V6400, ~V0002,anos18_fund, svytotal, na.rm = TRUE))

anos_18<-subset(amostra,V6036>=18&uf=="AL")

df1<-as.data.frame(svyby(~ V6400, ~V0002,anos_18, svytotal, na.rm = TRUE))

df$df<-"fundamental incompleto"
df1$df<-"sem instrução e fundamental incompleto"

df<-rbind(df,df1)

write.csv(df,'fund.csv')
