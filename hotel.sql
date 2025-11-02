CREATE SCHEMA IF NOT EXISTS hotel;  -- CRIAÇÃO DO SCHEMA "hotel"

CREATE TABLE IF NOT EXISTS hotel.reservas(  -- CRIAÇÃO DA TABELA QUE VAI RECEBER OS DADOS DO CSV. ESSA SERÁ NOSSA TABELA BASE
id_reserva INTEGER,
nome_hospede VARCHAR,
data_checkin DATE,
data_checkout DATE,
tipo_quarto VARCHAR,
valor_diaria NUMERIC 
);

COPY hotel.reservas                                    -- USANDO COMANDO COPY PARA COPIAR OS DADOS DO ARQUIVO CSV BAIXADO NA MÁQUINA           
FROM 'C:\Users\lucas\Desktop\exercicios\reservas.csv'  -- DIZENDO O CAMINHO DO ARQUIVO CSV
DELIMITER ','                                          -- DIZENDO QUE OS DADOS ESTÃO DIVIDIDOS PELO DELIMITADOR ","
CSV HEADER;                                            -- DIZENDO AO COPY QUE ELE VAI TER QUE LER UM ARQUIVO CSV


-- ANÁLISE: PODEMOS TER MUITAS RESERVAS NA MESMA DATA;
-- A QUANTIDADE DE DIAS IMPLICA DIRETAMENTE EM VALOR DIARIA,
-- LOGO CONCLUIMOS QUE PRECISAMOS DESCORBRIR QUANTO SE PAGA POR DIA EM UM QUARTO;
-- PERCEBEMOS VERIFICANDO A MUDANÇA DE VALOR QUE UM HOSPEDE PAGA EM UMA DIARIA PARA QUARTOS DO MESMO TIPO
-- QUE PODEM EXISTIR DIFERENTES QUATOS DE MESMO TIPO E QUE NÃO TEMOS ESSA INFORMAÇÃO NA TABELA BASE, ENTÃO
-- PRECISAMOS EXTRAIR ESSA INFORMAÇÃO E COLOCALA EM UMA TABELA ENTIDADE QUE SE REFIRA A QAURTO;
-- ANÁLISANDO O CONJUNTO DE INFORMAÇÕES DESCRITIVOS, CONCLUO QUE PRECISAMOS DE UMA TABELA DIMENSÃO PARA
-- CADA QUARTO E UMA TABELA DIMENSÃO PARA CADA HOSPEDE.


-- CRIANOD UMA TABELA HOSPEDE 

CREATE IF NOT EXISTS TABLE hotel.hospede(       -- CRIANDO A TABELAS "hospede" NO SCHEMA "hotel"         
id_hospede SERIAL NOT NULL,                     -- DEFININDO QUE O ID SERÁ SERIAL E NÃO NULO
nome_hospede VARCHAR NOT NULL UNIQUE,           -- IDENTIFICANDO O NOME ED CADA HOSPEDE
CONSTRAINT pk_hospede PRIMARY KEY (id_hospede)  -- DANDO A COLUNA "id_hospede" A CARACTERISTICA DE PRIMARY KEY
);

-- INSERINDO VALORES REFERENTES AOS a coluna "nome_hospede" DA TABELA BASE 
-- PARA A COLUNA "nome_hospede"  DA TABELA "hotel.hospede"

INSERT INTO hotel.hospede(nome_hospede)  -- DEFININDO QUAL TABELA E QUAL COLUNA RECEBE OS DADOS
SELECT nome_hospede                      -- PUXANDO OS DADOS DIRETAMENTE DA TABELA BASE USANDO SELECT 
FROM hotel.reservas;


-- CRIANDO UMA TABELA QUARTO

CREATE TABLE IF NOT EXISTS hotel.quarto(       -- CRIANDO UMA TABELA "quarto" NO SCHEMA "HOTEL"
id_quarto SERIAL NOT NULL,                     -- AQUI DEFINIMOS QUE O ID SERÁ SERIAL E NÃO NULO      
tipo_quarto VARCHAR,                           -- CRIANDO UMA COLUNA PARA O TIPO DE QUARTO QUE VIMOS NA TABELA BASE
diaria_quarto NUMERIC,                         -- CRIANDO UMA COLUNA PARA ARMAZENAR O VALOR DA DIÁRIA DE CADA QUARTO
CONSTRAINT pk_quarto PRIMARY KEY (id_quarto)   -- DANDO A COLUNA "id_quarto" A CARACTERISTICA DE PRIMARY KEY
);

-- INSERINDO OS DADOS DA TABELA BASE QUE CONDIZEM COM 
-- NECESSIDADE DA CRIAÇÃO DE UMA TABELA PARA QUARTOS

INSERT INTO hotel.quarto(tipo_quarto,diaria_quarto)                                             -- DEFININDO QUAL TABELA E QUAL COLUNA RECEBE OS DADOS
SELECT                                                                                          -- PUXANDO OS DADOS DIRETAMENTE DA TABELA BASE USANDO SELECT
tipo_quarto,
ROUND(valor_diaria / EXTRACT(DAY FROM AGE(data_checkout,data_checkin)),2) as  diaria_quarto     -- 	DEFININDO AS DATAS COMO IDADE PARA CONSEGUIRMOS EXTRAIR OS DIAS
FROM hotel.reservas                                                                             -- E DIVIDIMOS O VALOR TOTAL POR ESSE RESULTADO GERANDO A COLUNA "diaria_quarto"
GROUP BY tipo_quarto, diaria_quarto                                                             -- AGRUPAMOS PELAS 2 COLUNAS PARA NAO TERMOS REPRTIÇÃO DE VALORES QUE SE REFIRAM AO MESMO QUARTO
ORDER BY tipo_quarto;                                                                           -- ORDENANDO PELO TIPO DE QUATO PARA MANTER A ORGANIZAÇÃO 

 
-- CRIAÇÃO DE UMA TABELA FATO/TRANSACIONAL

CREATE TABLE hotel.reserva(
id_reserva SERIAL NOT NULL,     -- CHAVE PRIMARIA DA NOVA TABELA 
id_hospede INTEGER NOT NULL,    -- REFERENCIA A TABELA "hospede"
id_quarto INTEGER NOT NULL,     -- REFERENCIA A TABELA "quarto"
data_checkin DATE,              -- DATA DE ENTRADA DO HOSPEDE
data_checkout DATE,             -- DATA DE SAÍDA DO HOSPEDE
total_pago NUMERIC NOT NULL,    -- TOTAL A SER PAGO PELO HOSPEDE 
CONSTRAINT pk_reserva PRIMARY KEY (id_reserva),                   
CONSTRAINT fk_id_hospede FOREIGN KEY (id_hospede)
REFERENCES hotel.hospede (id_hospede),
CONSTRAINT fk_id_quarto FOREIGN KEY (id_quarto)
REFERENCES hotel.quarto (id_quarto)
);
  
ALTER TABLE hotel.reserva                                                                     -- 	RESOLVI DEFINIR UNICIDADE CMOPOSTA PARA CASO ACONTEÇA DE UM 
ADD CONSTRAINT uq_reserva_unica UNIQUE (id_hospede, id_quarto, data_checkin, data_checkout);  -- MESMO HOSPEDE ALUGAR O MESMO QUARTO EM DATAS DIFERENTES, EU PERMITO 
ALTER TABLE hotel.reserva                                                                     -- QUE O NOMES DE HOSPEDE SE REPITAM ASSIM COMO ID DO QUARTO E AS DATAS 
ADD CONSTRAINT uq_quarto_checkin_unico                                                        -- MAS NUNCA DE FORMA CONJUNTA, E TAMBÉM CRIEI UMA RESTRIÇÃO QUE DEFINE 
UNIQUE (id_quarto, data_checkin);                                                             -- QUE O MESMO QUARTO NÃO PODE TER O MESMO CHECKIN NO MESMO DIA.                               


-- INSERINDO OS VALORES NA TABELA FATO/TRANSACIONA                                                                                              

INSERT INTO hotel.reserva(id_hospede,id_quarto,data_checkin,data_checkout,total_pago)      -- 	DEFININDO AS COLUNAS QUE VAO RECEBER OS VALORES  
SELECT                                                                                     -- NO SELECT USAMOS ALIAS PARA CADA TABLE PARA FACILITAR A VIDA
h.id_hospede,                                                 
q.id_quarto,
r.data_checkin,
r.data_checkout,
r.valor_diaria
FROM hotel.reservas r                 -- USANDO A TABELA BASE COMO A PRINCIPAL POIS ELA FAZ LIGAÇÃO COM TODAS QUE VAMOS USAR E DAMOS A ELA UM ALIAS
INNER JOIN hotel.hospede h            -- USANDO INNER JOIN PARA JUNTAR AS INFORMACOES QUE CORRESPONDE DE CADA TABELA
ON h.nome_hospede = r.nome_hospede    -- 	CRIANDO UMA COMPARAÇÃO PARA O INNER JOIN SÓ FAZER A JUNÇÃO QUANDO OS VALORES DAS COLUNAS CORRESPONDEREM
INNER JOIN (                          -- CRIANDO UM INNER JOIN DE UMA SUBSELEÇÃO QUE TRAZ SOMENTE O VALOR MINIMO DE "id_quarto" E AGRUPA POR "tipo_quarto"
SELECT                                -- EVITANDO UM RESULTADO DE 4 OPÇÕES JÁ QUE O SQL ENTENDERIA QUE SERIA A COMBINAÇÃO DE TODAS AS OCORRENCIAS DE VALORES 
MIN(id_quarto) AS id_quarto,          -- ENTRE AS TABELAS, ENTÃO PEGAMOS UM REPRESENTANTE PARA CADA TIPO DE QUARTO PARA EVITAR ISSO E GERAR UNICIDADE.
tipo_quarto
FROM hotel.quarto
GROUP BY tipo_quarto
ORDER BY id_quarto
) AS q
ON q.tipo_quarto = r.tipo_quarto 





