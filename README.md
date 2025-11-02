# 🏨 dimensional-model-hotel

## ✨ Projeto de Modelagem Dimensional — Sistema de Reservas de Hotel

Desenvolvi este projeto a partir de um minicenário proposto em sala de aula, utilizando um arquivo CSV com dados brutos de reservas de hotel. O objetivo principal foi aplicar e consolidar os conceitos de **Modelagem Dimensional** (Schema Estrela) em um ambiente PostgreSQL.

---

## 🎯 Objetivo

Construir um **Modelo Estrela** a partir de uma base transacional (CSV), criando e populando:
1.  Tabelas de Dimensão (Dimensão Hóspede e Dimensão Quarto).
2.  Tabela Fato (Fato Reserva), limpa e relacional, pronta para análises de Business Intelligence (BI).

## 📊 Análise e Entendimento da Base Bruta

A base inicial, carregada em uma tabela `hotel.reservas`, continha dados brutos com colunas como:
id_reserva, nome_hospede, data_checkin, data_checkout, tipo_quarto, valor_diaria


Durante a análise, foram identificados pontos-chave para a modelagem:
* Um mesmo tipo de quarto poderia ter diferentes valores de diária ao longo do tempo.
* Um hóspede poderia ter várias reservas em datas distintas.
* Era necessário padronizar o valor por diária de cada quarto, o que exigia cálculos baseados nas datas de check-in e check-out.

Essa análise levou à conclusão de que as informações descritivas deveriam ser separadas nas Dimensões, e os dados transacionais e métricas na Tabela Fato.

## ⚙️ Etapas de Implementação

### 1. Criação do Schema e Carga da Tabela Base

* Criação do schema `hotel`.
* Criação da tabela `hotel.reservas` para receber a fonte de dados bruta (CSV) utilizando o comando `COPY`.

### 2. Criação das Dimensões

Foram criadas duas tabelas de dimensão para armazenar dados descritivos, garantindo a unicidade e a normalização.

#### **A. Dimensão Hóspede (`hotel.hospede`)**
* Contém informações únicas de cada hóspede.
* **Chave Primária:** `id_hospede`.
* Foi aplicada a restrição `UNIQUE(nome_hospede)` para garantir que cada nome seja registrado apenas uma vez.

#### **B. Dimensão Quarto (`hotel.quarto`)**
* Armazena o tipo de quarto e o seu valor de diária.
* O **valor da diária** foi calculado e normalizado a partir da base bruta, usando a fórmula:
    ```sql
    ROUND(valor_diaria / EXTRACT(DAY FROM AGE(data_checkout, data_checkin)), 2)
    ```
* Os resultados foram agrupados por `tipo_quarto` e `valor_diaria` para evitar repetições desnecessárias.

### 3. Criação da Tabela Fato (`hotel.reserva`)

A tabela fato foi projetada para consolidar as transações, conectando as dimensões através de chaves estrangeiras (`id_hospede` e `id_quarto`).

**Restrições de Integridade (Garantia de Qualidade dos Dados):**
* `UNIQUE (id_hospede, id_quarto, data_checkin, data_checkout)`: Garante que um hóspede possa ter várias reservas, mas impede reservas idênticas para as mesmas datas.
* `UNIQUE (id_quarto, data_checkin)`: Impede reservas duplicadas para o mesmo quarto em um mesmo dia.

...
### 4. Inserção de Dados na Tabela Fato

Os dados foram carregados na tabela fato usando **`INNER JOINs`** entre a tabela base (`hotel.reservas`) e as tabelas dimensão.

Para resolver a duplicidade de correspondências entre tipos de quarto (caso um mesmo `tipo_quarto` tivesse sido inserido mais de uma vez na dimensão), foi utilizada uma subquery para trazer apenas o menor `id_quarto` para cada tipo, assegurando a unicidade no `JOIN`:

```sql
SELECT MIN(id_quarto) AS id_quarto, tipo_quarto
FROM hotel.quarto
GROUP BY tipo_quarto
```
🧠 Conclusão: O projeto consolida o processo completo de Extração, Transformação e Modelagem (ETL) de dados, resultando em um modelo estrela robusto e otimizado para análises de Business Intelligence (BI).A partir de uma simples fonte CSV, foi possível construir uma estrutura de dados relacional e limpa, pronta para responder a questões estratégicas como:Total de reservas por tipo de quarto.Faturamento por período.Taxa de ocupação e outros indicadores.🛠️ Tecnologias UtilizadasTecnologiaFinalidadePostgreSQLModelagem de dados, DDL, DML e carga de dados (ETL).SQLLinguagem de definição e manipulação de dados.CSVFonte de dados inicial (base bruta).👨‍💻 AutorLucas LimaEstudante de Análise e Desenvolvimento de Sistemas (Farias Brito)Formação em Data Analytics com IA (Digital College)🔗 LinkedIn
