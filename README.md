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



3.
Para validação dos dados de compras, foi considerado o relacionamento entre as tabelas pedido_compra e entradas_mercadoria por meio do campo ordem_compra, conforme instrução do case. A interpretação adotada foi a de que qtde_pedida representa a quantidade solicitada ao fornecedor e qtde_recebida representa a quantidade efetivamente recebida na entrada de mercadoria vinculada ao pedido. A partir desse cruzamento, foi possível identificar pedidos atendidos integralmente, parcialmente e casos com possíveis inconsistências de relacionamento ou de dados.


<img width="1015" height="810" alt="image" src="https://github.com/user-attachments/assets/ab8911ca-338e-4d52-8653-9c1e1ad85c35" />




