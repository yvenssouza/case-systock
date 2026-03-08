# Case Técnico – Analista de Integração de Dados

## Ambiente utilizado

* PostgreSQL rodando em container Docker
* Gerenciamento via Portainer
* Acesso ao banco através do DBeaver
* Sistema operacional Linux (Ubuntu Server)

## Criação das tabelas

As tabelas foram criadas utilizando o SQL fornecido no teste.

Durante a execução foram identificadas algumas inconsistências que impediam a criação das tabelas no PostgreSQL.

## Correções realizadas

### entradas_mercadoria

A chave primária utilizava a coluna `ordem_compra`, porém essa coluna não estava definida na estrutura da tabela.

Correção aplicada:

* inclusão da coluna `ordem_compra` na tabela

### produtos_filial

Foram encontrados alguns problemas:

* ausência de vírgula antes do CONSTRAINT
* chave primária utilizando coluna inexistente `idproduto`
* erros de digitação nas colunas `decricao` e `idfonecedor`

Correções aplicadas:

* inclusão da vírgula
* alteração da chave primária para `(filial_id, produto_id)`
* correção dos nomes das colunas

### fornecedor

A chave primária fazia referência à coluna `idproduto`, que não existe na tabela.

Correção aplicada:

* chave primária alterada para utilizar apenas `idfornecedor`

## Estrutura final do banco

As tabelas criadas foram:

* venda
* pedido_compra
* entradas_mercadoria
* produtos_filial
* fornecedor

Parte 1 – Documentação do Processo de Importação
Ferramenta utilizada

A importação dos dados foi realizada utilizando PostgreSQL em ambiente Linux, com o banco executando em container Docker, administração via Portainer e acesso pela ferramenta DBeaver. A planilha base_teste_systock.xlsx foi utilizada como fonte dos dados, com cada aba representando uma entidade do processo: venda, pedido_compra, entradas_mercadoria, produtos_filial e fornecedor.

Estrutura da planilha

A planilha foi organizada em cinco abas, cada uma correspondente a uma tabela do banco de dados:

venda: dados de vendas por produto, data, item, filial, quantidade e valor unitário.

pedido_compra: dados de pedidos de compra, incluindo produto, ordem de compra, quantidade pedida, quantidade entregue, datas e fornecedor.

entradas_mercadoria: dados de recebimento de mercadorias, incluindo nota fiscal, produto, ordem de compra, quantidade recebida e custo unitário.

produtos_filial: cadastro de produtos por filial, com descrição, estoque, preços e fornecedor.

fornecedor: cadastro de fornecedores com identificador e razão social.

Para garantir maior controle no processo, os dados foram importados inicialmente para tabelas de staging, com colunas do tipo texto, permitindo inspeção e tratamento antes da carga final nas tabelas definitivas.

Processo de importação

O processo foi executado em duas etapas:

Importação dos dados brutos da planilha para tabelas de staging.

Inserção dos dados tratados das tabelas de staging para as tabelas finais do modelo relacional.

Essa abordagem foi adotada para evitar falhas de carga direta, facilitar validações e permitir correções de formato e consistência antes da gravação definitiva no banco.

Tratamentos aplicados

Durante o carregamento dos dados das tabelas de staging para as tabelas finais, foram aplicados os seguintes tratamentos:

remoção de espaços em branco com TRIM();

transformação de valores vazios em NULL com NULLIF();

substituição de valores nulos por padrões controlados com COALESCE();

conversão de tipos textuais para date, int4, int8, float8 e numeric;

padronização de datas conforme o formato encontrado na planilha;

cálculo do campo qtde_pendente na tabela pedido_compra, com base na regra qtde_pedida - qtde_entregue;

tratamento do identificador de fornecedor na tabela produtos_filial, removendo o prefixo textual quando necessário para adequação ao tipo da coluna final;

validação de campos obrigatórios nulos;

verificação de possíveis duplicidades com base nas chaves primárias de cada tabela.

Validações realizadas

Após a importação, foram executadas consultas de validação para conferir:

quantidade de registros entre staging e tabela final;

existência de campos obrigatórios vazios;

duplicidades em colunas que compõem chave primária;

coerência entre quantidades pedidas, entregues e pendentes;

consistência do relacionamento entre pedido_compra e entradas_mercadoria por meio do campo ordem_compra.

Na validação entre compras e entradas, foi adotada a interpretação de que qtde_pedida representa a quantidade solicitada ao fornecedor e qtde_recebida representa a quantidade efetivamente recebida na entrada vinculada à ordem de compra, permitindo identificar pedidos totalmente atendidos, parcialmente atendidos e registros com possível inconsistência.


<img width="600" height="600" alt="image" src="https://github.com/user-attachments/assets/ab8911ca-338e-4d52-8653-9c1e1ad85c35" />


Ajustes e correções realizados durante o processo

Além das correções estruturais já documentadas no schema, também foram observados ajustes de importação e compatibilização de layout, como:

uso de tabelas de staging para evitar perda de dados durante a carga;

adequação de nomes de colunas entre planilha e banco;

tratamento de valores nulos ou ausentes em colunas numéricas;

revisão do relacionamento entre pedidos e entradas de mercadoria com base na regra do case;

identificação de inconsistências intencionais na base, usadas como parte da análise do processo de integração.



## Parte 2 – Consultas SQL Básicas

### 1. Consumo por produto no mês de fevereiro de 2025

SELECT
    v.produto_id,
    SUM(v.qtde_vendida) AS total_qtde_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS total_valor_vendido
FROM public.venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao < DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;

A consulta agrupa as vendas por produto e calcula, para o mês de fevereiro de 2025, o total vendido em quantidade e o valor total vendido em reais.

### 2.Produtos com requisição pendente

SELECT
    pc.ordem_compra,
    pc.item,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida,
    pc.qtde_pedida - COALESCE(SUM(em.qtde_recebida), 0) AS qtde_pendente
FROM public.pedido_compra pc
LEFT JOIN public.entradas_mercadoria em
       ON em.ordem_compra = pc.ordem_compra
      AND em.produto_id = pc.produto_id
      AND em.item = pc.item
GROUP BY
    pc.ordem_compra,
    pc.item,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida
HAVING pc.qtde_pedida > COALESCE(SUM(em.qtde_recebida), 0)
ORDER BY pc.ordem_compra, pc.item, pc.produto_id;


A consulta relaciona pedidos de compra e entradas de mercadoria por ordem de compra, item e produto, retornando os casos em que a quantidade recebida foi menor do que a quantidade pedida.



Parte 3 – Transformações de Dados

Nesta etapa, foram criadas consultas SQL para transformação e apresentação dos dados da tabela `pedido_compra`, além de uma trigger para geração automática de fornecedor na tabela `produtos_filial`.

### 1. Concatenação de `produto_id` e `descricao_produto`


SELECT
    pc.produto_id || ' - ' || pc.descricao_produto AS "Produto"
FROM public.pedido_compra pc;


consulta concatena o código e a descrição do produto no formato solicitado pelo case, por exemplo: P1 - Produto 1.

2. Formatação da data para DD/MM/YYYY
SELECT
    to_char(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc;

A consulta utiliza a função to_char() para exibir a data no padrão brasileiro DD/MM/YYYY.

3. Filtro de produtos requisitados com quantidade maior que 10
SELECT
    pc.produto_id || ' - ' || pc.descricao_produto AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    to_char(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
WHERE pc.qtde_pedida > 10
ORDER BY pc.produto_id, pc.data_pedido;

Foi adotada a interpretação de produtos com qtde_pedida > 10, pois essa leitura se mostrou mais aderente ao exemplo apresentado no enunciado. A consulta retorna o produto formatado, a quantidade requisitada e a data de solicitação.

4. Trigger para geração automática de idfornecedor
Sequence
CREATE SEQUENCE seq_idfornecedor
START 21
INCREMENT 1;
Função da trigger
CREATE OR REPLACE FUNCTION fn_gerar_fornecedor_produto()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    novo_id int;
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        novo_id := nextval('seq_idfornecedor');
        NEW.idfornecedor := novo_id;

        INSERT INTO public.fornecedor (idfornecedor, razao_social)
        VALUES ('F' || novo_id, 'FORNECEDOR AUTO ' || novo_id);
    END IF;

    RETURN NEW;
END;
$$;
Trigger
CREATE TRIGGER trg_gerar_fornecedor_produto
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW
EXECUTE FUNCTION fn_gerar_fornecedor_produto();
Teste de execução
INSERT INTO public.produtos_filial (
    filial_id,
    produto_id,
    descricao,
    estoque,
    preco_unitario,
    preco_compra,
    preco_venda,
    idfornecedor
)
VALUES (
    1,
    'P999',
    'Produto Teste',
    10,
    50,
    30,
    70,
    NULL
);

A trigger foi criada para preencher automaticamente o campo idfornecedor ao inserir um novo produto sem fornecedor informado. Além disso, a função também cria o registro correspondente na tabela fornecedor, mantendo o relacionamento entre as tabelas.








