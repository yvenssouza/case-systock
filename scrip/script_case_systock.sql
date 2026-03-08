
-- criação das tabelas principais

CREATE TABLE public.venda(
venda_id int8 NOT NULL, 
data_emissao date NOT NULL,
horariomov varchar(8) DEFAULT '00:00:00'::character varying NOT NULL,
produto_id varchar(25) DEFAULT ''::character varying NOT NULL,
qtde_vendida float8 NULL,
valor_unitario numeric(12, 4) DEFAULT 0 NOT NULL,
filial_id int8 DEFAULT 1 NOT NULL, item int4 DEFAULT 0 NOT NULL,
unidade_medida varchar(3) NULL,
CONSTRAINT pk_consumo PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov) );

CREATE TABLE public.pedido_compra(
    pedido_id float8 DEFAULT 0 NOT NULL,
    data_pedido date NULL,
    item float8 DEFAULT 0 NOT NULL,
    produto_id varchar(25) DEFAULT '0' NOT NULL,
    descricao_produto varchar(255) NULL,
    ordem_compra float8 DEFAULT 0 NOT NULL,
    qtde_pedida float8 NULL,
    filial_id int4 NULL,
    data_entrega date NULL,
    qtde_entregue float8 DEFAULT 0 NOT NULL,
    qtde_pendente float8 DEFAULT 0 NOT NULL,
    preco_compra float8 DEFAULT 0 NULL,
    fornecedor_id int4 DEFAULT 0 NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id , produto_id, item)
);

CREATE TABLE public.entradas_mercadoria (
data_entrada date NULL,
nro_nfe varchar(255) NOT NULL,
ordem_compra int8 NOT NULL,
item float8 DEFAULT 0 NOT NULL, 
produto_id varchar(25) DEFAULT '0' NOT NULL,
descricao_produto varchar(255) NULL,
qtde_recebida float8 NULL,
filial_id int4 NULL,
custo_unitario numeric(12,4) DEFAULT 0 NOT NULL,
CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe) );

CREATE TABLE public.produtos_filial(
filial_id int4 null,
produto_id varchar(255) NOT NULL,
descricao varchar(255) NOT NULL,
estoque float8 DEFAULT 0 NOT NULL,
preco_unitario float8 DEFAULT '0' NOT NULL,
preco_compra float8 DEFAULT '0' NOT NULL,
preco_venda float8 DEFAULT '0' NOT NULL,
idfornecedor int4 null,
CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id) );

CREATE TABLE public.fornecedor(
idfornecedor varchar(25) NOT NULL,
razao_social varchar(255) NOT NULL,
CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor) );


-- consultas iniciais

select * from pedido_compra;
select * from venda;


-- staging pedido_compra

CREATE TABLE public.stg_pedido_compra (
    pedido_id text,
    data_pedido text,
    item text,
    produto_id text,
    descricao_produto text,
    ordem_compra text,
    qtde_pedida text,
    filial_id text,
    data_entrega text,
    qtde_entregue text,
    qtde_pendente text,
    preco_compra text,
    fornecedor_id text
);

select * from stg_pedido_compra spc;

SELECT *
FROM public.stg_pedido_compra
LIMIT 20;

SELECT *
FROM public.stg_pedido_compra
WHERE pedido_id IS NULL
   OR pedido_id = ''
   OR produto_id IS NULL
   OR produto_id = '';

SELECT
    COALESCE(NULLIF(TRIM(pedido_id), ''), '0')::float8 AS pedido_id,
    NULLIF(TRIM(data_pedido), '')::date AS data_pedido,
    COALESCE(NULLIF(TRIM(item), ''), '0')::float8 AS item,
    COALESCE(NULLIF(TRIM(produto_id), ''), '0') AS produto_id,
    NULLIF(TRIM(descricao_produto), '') AS descricao_produto,
    COALESCE(NULLIF(TRIM(ordem_compra), ''), '0')::float8 AS ordem_compra,
    COALESCE(NULLIF(TRIM(qtde_pedida), ''), '0')::float8 AS qtde_pedida,
    NULLIF(TRIM(filial_id), '')::int4 AS filial_id,
    NULLIF(TRIM(data_entrega), '')::date AS data_entrega,
    COALESCE(NULLIF(TRIM(qtde_entregue), ''), '0')::float8 AS qtde_entregue,
    COALESCE(NULLIF(TRIM(qtde_pedida), ''), '0')::float8
      - COALESCE(NULLIF(TRIM(qtde_entregue), ''), '0')::float8 AS qtde_pendente,
    COALESCE(NULLIF(TRIM(preco_compra), ''), '0')::float8 AS preco_compra,
    COALESCE(NULLIF(TRIM(fornecedor_id), ''), '0')::int4 AS fornecedor_id
FROM public.stg_pedido_compra
LIMIT 20;

INSERT INTO public.pedido_compra (
    pedido_id,
    data_pedido,
    item,
    produto_id,
    descricao_produto,
    ordem_compra,
    qtde_pedida,
    filial_id,
    data_entrega,
    qtde_entregue,
    qtde_pendente,
    preco_compra,
    fornecedor_id
)
SELECT
    COALESCE(NULLIF(TRIM(pedido_id), ''), '0')::float8,
    NULLIF(TRIM(data_pedido), '')::date,
    COALESCE(NULLIF(TRIM(item), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(produto_id), ''), '0'),
    NULLIF(TRIM(descricao_produto), ''),
    COALESCE(NULLIF(TRIM(ordem_compra), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(qtde_pedida), ''), '0')::float8,
    NULLIF(TRIM(filial_id), '')::int4,
    NULLIF(TRIM(data_entrega), '')::date,
    COALESCE(NULLIF(TRIM(qtde_entregue), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(qtde_pedida), ''), '0')::float8
      - COALESCE(NULLIF(TRIM(qtde_entregue), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(preco_compra), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(fornecedor_id), ''), '0')::int4
FROM public.stg_pedido_compra;

SELECT * FROM public.stg_pedido_compra;
SELECT * FROM public.pedido_compra;

SELECT
    pedido_id,
    produto_id,
    item,
    COUNT(*)
FROM public.pedido_compra
GROUP BY pedido_id, produto_id, item
HAVING COUNT(*) > 1;


-- validações stg_venda

SELECT *
FROM stg_venda
WHERE venda_id IS NULL
   OR data_emissao IS NULL
   OR horariomov IS NULL
   OR produto_id IS NULL
   OR filial_id IS NULL
   OR item IS NULL;

SELECT *
FROM stg_venda
WHERE TRIM(data_emissao) = '';

SELECT *
FROM stg_venda
WHERE LENGTH(unidade_medida) > 3;

SELECT
    filial_id,
    venda_id,
    data_emissao,
    produto_id,
    item,
    horariomov,
    COUNT(*)
FROM stg_venda
GROUP BY
    filial_id,
    venda_id,
    data_emissao,
    produto_id,
    item,
    horariomov
HAVING COUNT(*) > 1;

SELECT DISTINCT data_emissao
FROM stg_venda
ORDER BY data_emissao
LIMIT 20;

SELECT COUNT(*) FROM stg_venda;
SELECT COUNT(*) FROM venda;

SELECT *
FROM venda
LIMIT 10;

SELECT *
FROM pedido_compra
LIMIT 10;


-- staging entradas_mercadoria

CREATE TABLE public.stg_entradas_mercadoria (
    data_entrada text,
    nro_nfe text,
    ordem_compra text,
    item text,
    produto_id text,
    descricao_produto text,
    qtde_recebida text,
    filial_id text,
    custo_unitario text
);

SELECT *
FROM public.stg_entradas_mercadoria
LIMIT 20;

SELECT *
FROM public.stg_entradas_mercadoria
WHERE nro_nfe IS NULL
   OR TRIM(nro_nfe) = ''
   OR ordem_compra IS NULL
   OR TRIM(ordem_compra) = ''
   OR item IS NULL
   OR TRIM(item) = ''
   OR produto_id IS NULL
   OR TRIM(produto_id) = '';

SELECT *
FROM public.stg_entradas_mercadoria
WHERE data_entrada IS NULL
   OR TRIM(data_entrada) = '';

SELECT
    ordem_compra,
    item,
    produto_id,
    nro_nfe,
    COUNT(*)
FROM public.stg_entradas_mercadoria
GROUP BY ordem_compra, item, produto_id, nro_nfe
HAVING COUNT(*) > 1;

SELECT DISTINCT data_entrada
FROM public.stg_entradas_mercadoria
ORDER BY data_entrada
LIMIT 20;

SELECT
    NULLIF(TRIM(data_entrada), '')::date AS data_entrada,
    COALESCE(NULLIF(TRIM(nro_nfe), ''), 'SEM_NFE') AS nro_nfe,
    COALESCE(NULLIF(TRIM(ordem_compra), ''), '0')::int8 AS ordem_compra,
    COALESCE(NULLIF(TRIM(item), ''), '0')::float8 AS item,
    COALESCE(NULLIF(TRIM(produto_id), ''), '0') AS produto_id,
    NULLIF(TRIM(descricao_produto), '') AS descricao_produto,
    COALESCE(NULLIF(TRIM(qtde_recebida), ''), '0')::float8 AS qtde_recebida,
    NULLIF(TRIM(filial_id), '')::int4 AS filial_id,
    COALESCE(NULLIF(TRIM(custo_unitario), ''), '0')::numeric(12,4) AS custo_unitario
FROM public.stg_entradas_mercadoria
LIMIT 20;

INSERT INTO public.entradas_mercadoria (
    data_entrada,
    nro_nfe,
    ordem_compra,
    item,
    produto_id,
    descricao_produto,
    qtde_recebida,
    filial_id,
    custo_unitario
)
SELECT
    NULLIF(TRIM(data_entrada), '')::date,
    COALESCE(NULLIF(TRIM(nro_nfe), ''), 'SEM_NFE'),
    COALESCE(NULLIF(TRIM(ordem_compra), ''), '0')::int8,
    COALESCE(NULLIF(TRIM(item), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(produto_id), ''), '0'),
    NULLIF(TRIM(descricao_produto), ''),
    COALESCE(NULLIF(TRIM(qtde_recebida), ''), '0')::float8,
    NULLIF(TRIM(filial_id), '')::int4,
    COALESCE(NULLIF(TRIM(custo_unitario), ''), '0')::numeric(12,4)
FROM public.stg_entradas_mercadoria;

SELECT COUNT(*) FROM public.stg_entradas_mercadoria;
SELECT COUNT(*) FROM public.entradas_mercadoria;

SELECT *
FROM public.entradas_mercadoria
WHERE qtde_recebida < 0
   OR custo_unitario < 0;

SELECT
    pc.ordem_compra,
    pc.produto_id,
    pc.qtde_pedida,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida
FROM public.pedido_compra pc
LEFT JOIN public.entradas_mercadoria em
       ON em.ordem_compra = pc.ordem_compra
      AND em.produto_id = pc.produto_id
      AND em.item = pc.item
GROUP BY pc.ordem_compra, pc.produto_id, pc.qtde_pedida
ORDER BY pc.ordem_compra;


-- staging produtos_filial

SELECT * FROM produtos_filial pf;

CREATE TABLE public.stg_produtos_filial (
    filial_id text,
    idproduto text,
    descricao text,
    estoque text,
    preco_unitario text,
    preco_compra text,
    preco_venda text,
    idfornecedor text
);

select * from public.stg_produtos_filial limit 10;
select * from public.produtos_filial limit 10;

SELECT *
FROM public.stg_produtos_filial
WHERE filial_id IS NULL OR TRIM(filial_id) = ''
   OR idproduto IS NULL OR TRIM(idproduto) = ''
   OR descricao IS NULL OR TRIM(descricao) = '';

SELECT DISTINCT idfornecedor
FROM public.stg_produtos_filial
ORDER BY idfornecedor;

SELECT
    NULLIF(TRIM(filial_id), '')::int4 AS filial_id,
    COALESCE(NULLIF(TRIM(idproduto), ''), '0') AS produto_id,
    NULLIF(TRIM(descricao), '') AS descricao,
    COALESCE(NULLIF(TRIM(estoque), ''), '0')::float8 AS estoque,
    COALESCE(NULLIF(TRIM(preco_unitario), ''), '0')::float8 AS preco_unitario,
    COALESCE(NULLIF(TRIM(preco_compra), ''), '0')::float8 AS preco_compra,
    COALESCE(NULLIF(TRIM(preco_venda), ''), '0')::float8 AS preco_venda,
    REPLACE(COALESCE(NULLIF(TRIM(idfornecedor), ''), 'F0'), 'F', '')::int4 AS idfornecedor
FROM public.stg_produtos_filial
LIMIT 20;

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
SELECT
    NULLIF(TRIM(filial_id), '')::int4,
    COALESCE(NULLIF(TRIM(idproduto), ''), '0'),
    NULLIF(TRIM(descricao), ''),
    COALESCE(NULLIF(TRIM(estoque), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(preco_unitario), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(preco_compra), ''), '0')::float8,
    COALESCE(NULLIF(TRIM(preco_venda), ''), '0')::float8,
    REPLACE(COALESCE(NULLIF(TRIM(idfornecedor), ''), 'F0'), 'F', '')::int4
FROM public.stg_produtos_filial;

select * from public.produtos_filial pf limit 10;


-- staging fornecedor

CREATE TABLE public.stg_fornecedor (
    idfornecedor text,
    razao_social text
);

select * from public.stg_fornecedor limit 10;

SELECT *
FROM public.stg_fornecedor
WHERE idfornecedor IS NULL OR TRIM(idfornecedor) = ''
   OR razao_social IS NULL OR TRIM(razao_social) = '';

SELECT
    idfornecedor,
    COUNT(*)
FROM public.stg_fornecedor
GROUP BY idfornecedor
HAVING COUNT(*) > 1;

SELECT
    COALESCE(NULLIF(TRIM(idfornecedor), ''), 'SEM_ID') AS idfornecedor,
    NULLIF(TRIM(razao_social), '') AS razao_social
FROM public.stg_fornecedor
LIMIT 20;

INSERT INTO public.fornecedor (
    idfornecedor,
    razao_social
)
SELECT
    COALESCE(NULLIF(TRIM(idfornecedor), ''), 'SEM_ID'),
    NULLIF(TRIM(razao_social), '')
FROM public.stg_fornecedor;

select * from fornecedor f limit 10;


-- parte 2

SELECT
    v.produto_id,
    SUM(v.qtde_vendida) AS total_qtde_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS total_valor_vendido
FROM public.venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao < DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;

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


-- parte 3

SELECT
    produto_id || ' - ' || descricao_produto AS produto
FROM public.pedido_compra;

SELECT
    to_char(data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM public.pedido_compra;

SELECT
    pc.produto_id || ' - ' || pc.descricao_produto AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    to_char(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
WHERE pc.qtde_pedida > 10
ORDER BY pc.produto_id, pc.data_pedido;

CREATE SEQUENCE seq_idfornecedor
START 21
INCREMENT 1;

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

CREATE TRIGGER trg_gerar_fornecedor_produto
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW
EXECUTE FUNCTION fn_gerar_fornecedor_produto();

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

SELECT *
FROM public.produtos_filial
WHERE produto_id = 'P999';
