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


