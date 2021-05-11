<h1 align="center">Censo Demográfico - Modelo de Download e tratamento dos dados amostrais -  Pessoas</h1>


Script para download e tratamento dos dados gerais da Amostra do censo de 2010 para diferentes UFs - Variáveis do registro de Pessoas.

Na linha 71 eu seleciono as UFs que desejo.

Nesse em específico estou selecionando a população do Estado de Alagoas acima de 18 anos e classificando de acordo com o nível de instrução, mas é possível utilizar o mesmo script para gerar outras informações.

A linha 82 do código é a linha de seleção das variáveis, nela é essencial que as variáveis para o desenho da amostra estejam presentes:
1. V0010 - Peso Amostral
2. V0011 - Área de Ponderação
3. V0300 - Controle 

As demais variáveis são opcionais, nesse caso escolho a V0633, V6400, V0002 e V6036, mas vai depender da sua análise.

Para escolher as variáveis a documentação se encontra em: https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/Documentacao.zip

Note que na linha 102 eu começo a transformar minhas variáveis, caso use outras é necessário trocar. As variáveis categóricas precisam ser transformadas em fator, as numéricas em número.

A partir da linha 116 eu crio minhas amostras com minhas variáveis de desejo
