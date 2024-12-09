#!/bin/bash
# Conecta-se ao banco de dados replicadb e crie a tabela orders
psql -U replicauser -d cloudwalkdb -c "
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    product_name TEXT,
    quantity INT,
    order_date DATE
);
"

#Cria a assinatura
psql -U replicauser -d cloudwalkdb -c "CREATE SUBSCRIPTION orderssub CONNECTION 'host=pg_master port=5432 dbname=cloudwalkdb user=masteruser password=masterpassword' PUBLICATION orderspub;"