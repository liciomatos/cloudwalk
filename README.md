# Configuração de Replicação no PostgreSQL

Este README explica os passos para configurar a replicação entre dois servidores PostgreSQL: `pg_master` (publicador) e `pg_replica` (assinante). A replicação permite manter uma cópia sincronizada dos dados entre os servidores, proporcionando redundância e alta disponibilidade.

## Pré-requisitos

- Docker e Docker Compose instalados
- Rede configurada entre os contêineres

## Estrutura do Projeto

```plaintext
project/
├── docker-compose.yaml
├── pg_master_init/
│   └── init-db.sql
├── pg_replica_init/
│   └── replica-init.sh
└── insert_data.py
```

## Rode o docker composer

``` 
docker-compose -f docker_composer.yaml up
``` 

## Será levantado um ambiente com os seguintes containers

- pg_master
- pg_replica
- pgadmin
- data_inserter

## Data Inserter
Ficará inserindo dados na PG_MASTER a cada 10 segundos.

## PG_MASTER
Banco postgreSQL com a tabela orders dentro do database cloudwalkdb

## PG_REPLICA
Banco postgreSQL com a tabela orders dentro do database cloudwalkdb sendo replicada da pg_master atra'ves de PUB/SUB do postgresql.

## PGADMIN
Console de administração do PostgreSQL para gerenciar os bancos pg_master e pg_replica. 
Possui um arquivo de configuração com as conecões para os bancos "pgadmin_config_bkp.josn" pode ser importado pelo browser direto.
O acesso é feito pelo ***localhost:8080***

## Script_partitions_orders.sql

Script em PgSQL para ser executado passo a passo para o particionamento da tabela orders.
