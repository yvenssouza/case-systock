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




