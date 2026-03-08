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



## Parte 4 – Estratégia de Validação com o Cliente

Imaginei esta etapa como uma reunião final de validação com o cliente, considerando os dados de **fevereiro de 2025** já importados, tratados e disponibilizados no banco. O objetivo dessa validação é garantir não apenas a integridade técnica da carga, mas também confirmar que os dados apresentados no sistema representam corretamente a operação real do cliente.

### 1. Principais pontos a validar com o cliente

Na reunião de validação, os principais pontos que eu validaria com o cliente seriam:

#### a) Vendas do período
O primeiro ponto seria validar se as vendas de fevereiro de 2025 carregadas no banco correspondem ao que o cliente espera visualizar no sistema. Nessa etapa, eu confirmaria:

- os produtos vendidos no período;
- o total vendido em quantidade por produto;
- o total vendido em valor por produto;
- se existem produtos com movimentação inesperada ou ausência de venda;
- se os números apresentados fazem sentido para a operação do cliente.

Essa validação é importante porque a venda é um dos principais indicadores operacionais e, se estiver incorreta, compromete a confiança em todo o restante da base.

#### b) Pedidos de compra e recebimentos
Também validaria os pedidos de compra emitidos no período e sua relação com as entradas de mercadoria. Os pontos de conferência seriam:

- produtos requisitados;
- quantidades pedidas;
- quantidades recebidas;
- quantidades pendentes;
- pedidos totalmente atendidos;
- pedidos parcialmente atendidos;
- pedidos sem recebimento.

Essa etapa é central porque o case informa que a entrada de mercadoria está vinculada ao pedido de compra por meio do campo `ordem_compra`.

#### c) Entradas de mercadoria
Em seguida, validaria se as entradas de mercadoria estão coerentes com os pedidos e com a lógica operacional do cliente. Nessa análise, verificaria:

- se as entradas estão associadas corretamente aos pedidos;
- se existem entradas sem pedido correspondente;
- se existem pedidos com recebimento maior que o solicitado;
- se a nota fiscal e a data de entrada parecem coerentes.

#### d) Cadastro de produtos
Também validaria se os dados cadastrais dos produtos foram importados corretamente, incluindo:

- código do produto;
- descrição;
- filial;
- estoque;
- preços de compra e venda;
- vínculo com fornecedor.

#### e) Cadastro de fornecedores
No cadastro de fornecedores, eu validaria:

- se todos os produtos possuem fornecedor vinculado;
- se os identificadores estão coerentes entre `produtos_filial` e `fornecedor`;
- se a razão social foi importada corretamente.

#### f) Regras de negócio
Como o teste contém erros intencionais, eu também validaria com o cliente a interpretação de algumas regras de negócio, principalmente:

- se `qtde_pendente = qtde_pedida - qtde_entregue` é a regra correta;
- se a entrada de mercadoria representa efetivamente o recebimento do pedido;
- se pedidos podem ser recebidos parcialmente;
- se é possível receber mais do que foi pedido em situações reais;
- se o identificador do fornecedor deve ser textual ou numérico internamente.

Essa etapa é essencial para garantir que a solução não esteja apenas tecnicamente correta, mas também alinhada ao processo do cliente.

### 2. Técnicas utilizadas para garantir exatidão e precisão dos dados

Para garantir a confiabilidade dos dados, eu utilizaria uma combinação de validações técnicas e validações funcionais.

#### a) Validação por amostragem
Selecionaria alguns registros relevantes de fevereiro de 2025 para conferência manual com o cliente, como:

- um produto com venda recorrente;
- um pedido de compra com recebimento parcial;
- um produto com pendência de recebimento;
- um cadastro de produto com fornecedor vinculado.

Essa técnica ajuda a confirmar se o que foi carregado no sistema representa corretamente os exemplos reais da operação.

#### b) Conciliação entre tabelas relacionadas
Faria cruzamentos entre tabelas para validar coerência entre os dados importados, por exemplo:

- `venda` x `produtos_filial`
- `pedido_compra` x `entradas_mercadoria`
- `produtos_filial` x `fornecedor`

Essa conciliação ajuda a identificar registros órfãos, divergências de quantidade e falhas de relacionamento.

#### c) Verificação de integridade
Executaria validações para conferir:

- campos obrigatórios nulos;
- duplicidades em chaves primárias;
- tipos de dados inconsistentes;
- valores negativos indevidos;
- ausência de registros esperados.

Esse tipo de verificação garante a integridade estrutural da base importada.

#### d) Comparação entre origem e banco final
Sempre que possível, compararia os dados da planilha de origem com os dados já carregados nas tabelas finais, validando:

- quantidade total de registros;
- datas;
- campos numéricos;
- campos calculados;
- relacionamentos.

Essa técnica ajuda a comprovar que o processo de carga e transformação preservou corretamente a informação.

#### e) Validação orientada ao negócio
Além da validação técnica, eu também confirmaria com o cliente se os números apresentados fazem sentido para a rotina operacional da empresa. Em implantação, isso é fundamental, porque nem toda inconsistência é erro de carga: em alguns casos, pode ser uma regra de negócio específica da operação.

### 3. Consultas deixadas prontas para a reunião de validação

A seguir estão as consultas que eu deixaria preparadas para a reunião com o cliente.

#### a) Consumo por produto no mês de fevereiro de 2025

```sql
SELECT
    v.produto_id,
    SUM(v.qtde_vendida) AS total_qtde_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS total_valor_vendido
FROM public.venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao < DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;
```

Essa consulta permite validar com o cliente o consumo por produto no período, tanto em quantidade quanto em valor.

#### b) Pedidos com pendência de recebimento

```sql
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
```

Essa consulta mostra os pedidos que ainda possuem saldo pendente de recebimento.

#### c) Pedidos totalmente atendidos

```sql
SELECT
    pc.ordem_compra,
    pc.item,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida
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
HAVING pc.qtde_pedida = COALESCE(SUM(em.qtde_recebida), 0)
ORDER BY pc.ordem_compra, pc.item, pc.produto_id;
```

Essa consulta ajuda a mostrar os pedidos em que a quantidade recebida corresponde exatamente à quantidade pedida.

#### d) Divergências em que a quantidade recebida superou a quantidade pedida

```sql
SELECT
    pc.ordem_compra,
    pc.item,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida
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
HAVING COALESCE(SUM(em.qtde_recebida), 0) > pc.qtde_pedida
ORDER BY pc.ordem_compra, pc.item, pc.produto_id;
```

Essa consulta é útil para identificar possíveis inconsistências de dados ou situações que precisem de validação adicional com o cliente.

#### e) Exibição amigável dos pedidos para apresentação em reunião

```sql
SELECT
    pc.produto_id || ' - ' || pc.descricao_produto AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    to_char(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
WHERE pc.qtde_pedida > 10
ORDER BY pc.produto_id, pc.data_pedido;
```

Essa consulta facilita a apresentação dos dados ao cliente, exibindo o produto formatado, a quantidade requisitada e a data de solicitação em formato amigável.

#### f) Produtos sem fornecedor

```sql
SELECT
    pf.filial_id,
    pf.produto_id,
    pf.descricao,
    pf.idfornecedor
FROM public.produtos_filial pf
WHERE pf.idfornecedor IS NULL;
```

Essa consulta ajuda a validar se existem cadastros incompletos na base de produtos.

#### g) Relacionamento entre produtos e fornecedores

```sql
SELECT
    pf.filial_id,
    pf.produto_id,
    pf.descricao,
    pf.idfornecedor,
    f.razao_social
FROM public.produtos_filial pf
LEFT JOIN public.fornecedor f
    ON 'F' || pf.idfornecedor::text = f.idfornecedor
ORDER BY pf.filial_id, pf.produto_id;
```

Essa consulta permite validar se os produtos estão corretamente associados aos fornecedores cadastrados.



## Observações finais

Durante o desenvolvimento do case, foram identificadas inconsistências intencionais no schema original, além de ambiguidades pontuais de interpretação. Essas situações foram tratadas com:

- correções estruturais;
- uso de tabelas de staging;
- validações SQL;
- documentação das decisões adotadas.

A solução foi construída com foco em rastreabilidade, consistência de dados e aderência aos requisitos propostos no desafio.








