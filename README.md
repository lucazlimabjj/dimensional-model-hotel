# dimensional-model-hotel
🏨 Projeto de Modelagem Dimensional — Sistema de Reservas de Hotel  Desenvolvi este projeto a partir de um minicenário proposto em sala de aula, utilizando um arquivo CSV com dados de reservas de hotel. O objetivo foi aplicar conceitos de modelagem dimensional no PostgreSQL, criando tabelas de dimensões e uma tabela fato a partir de uma base bruta.

🔍 Etapas do Projeto

1. Criação do Schema e Tabela Base
Iniciei o projeto criando o schema hotel e uma tabela chamada reservas, que recebeu os dados do arquivo CSV utilizando o comando COPY. Essa tabela representava a fonte de dados bruta, contendo colunas como:
id_reserva, nome_hospede, data_checkin, data_checkout, tipo_quarto e valor_diaria.

2. Análise e Entendimento da Base
Durante a análise, percebi que:

Um mesmo tipo de quarto poderia ter diferentes valores de diária;

Um hóspede poderia ter várias reservas em datas distintas;

Seria necessário calcular o valor por diária de cada quarto, com base nas datas de check-in e check-out.

Com isso, concluí que seria importante separar as informações descritivas em tabelas de dimensão e as transações em uma tabela fato.

3. Criação das Dimensões
Criei duas tabelas dimensão:

Dimensão Hóspede (hotel.hospede)

Contém informações únicas de cada hóspede, com chave primária id_hospede.

Os nomes foram extraídos diretamente da tabela base, garantindo unicidade com UNIQUE(nome_hospede).

Dimensão Quarto (hotel.quarto)

Armazena o tipo e o valor da diária de cada quarto.

O valor da diária foi calculado dividindo o valor_diaria pelo número de dias entre o check-in e o check-out, usando:

ROUND(valor_diaria / EXTRACT(DAY FROM AGE(data_checkout, data_checkin)), 2)


Os resultados foram agrupados por tipo de quarto e diária para evitar repetições.

4. Criação da Tabela Fato (hotel.reserva)
A tabela fato foi criada para consolidar as transações de reserva, conectando as dimensões por meio de chaves estrangeiras (id_hospede e id_quarto).
Também foram adicionadas restrições de integridade para garantir a consistência dos dados:

UNIQUE (id_hospede, id_quarto, data_checkin, data_checkout) → garante que um mesmo hóspede possa se hospedar várias vezes, mas nunca com as mesmas datas.

UNIQUE (id_quarto, data_checkin) → impede reservas duplicadas para o mesmo quarto no mesmo dia.

5. Inserção dos Dados na Tabela Fato
Os dados foram inseridos na tabela fato com base em joins entre a tabela base e as tabelas dimensão.
Para evitar duplicidade de correspondências entre tipos de quarto, utilizei uma subquery que traz apenas o menor id_quarto para cada tipo, garantindo unicidade no INNER JOIN:

SELECT MIN(id_quarto) AS id_quarto, tipo_quarto
FROM hotel.quarto
GROUP BY tipo_quarto

🧠 Conclusão

O projeto consolida o processo completo de extração, transformação e modelagem de dados em um contexto de Business Intelligence (BI).
A partir de uma simples planilha CSV, foi possível construir um modelo estrela, com dimensões normalizadas e uma tabela fato limpa e relacional, pronta para análises como:

total de reservas por tipo de quarto,

faturamento por período,

taxa de ocupação e muito mais.

🛠️ Tecnologias Utilizadas

PostgreSQL (modelagem e carga de dados)

SQL (DDL e DML)

CSV (fonte de dados)

👨‍💻 Autor

Lucas Lima
Estudante de Análise e Desenvolvimento de Sistemas (Farias Brito)
Formação em Data Analytics com IA (Digital College)
[🔗 LinkedIn](https://www.linkedin.com/in/lucas-lima-6113ab355)


