-- executar um de cada vez.

SELECT * FROM orders;

-- cria a nova tabela
CREATE TABLE orders_new (
    id SERIAL,
    product_name TEXT,
    quantity INT,
    order_date DATE,
    PRIMARY KEY (id, order_date)
) PARTITION BY RANGE (order_date);

-- cria as partiçoes
CREATE TABLE orders_new_2024_01 PARTITION OF orders_new
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_new_2024_02 PARTITION OF orders_new
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE orders_new_2024_03 PARTITION OF orders_new
FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

CREATE TABLE orders_new_2024_04 PARTITION OF orders_new
FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE orders_new_2024_05 PARTITION OF orders_new
FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE orders_new_2024_06 PARTITION OF orders_new
FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE orders_new_2024_07 PARTITION OF orders_new
FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

CREATE TABLE orders_new_2024_08 PARTITION OF orders_new
FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

CREATE TABLE orders_new_2024_09 PARTITION OF orders_new
FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

CREATE TABLE orders_new_2024_10 PARTITION OF orders_new
FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

CREATE TABLE orders_new_2024_11 PARTITION OF orders_new
FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE orders_new_2024_12 PARTITION OF orders_new
FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');


-- cria uma view para visualizar todos os pedidos da tabela orders e particionada
CREATE OR REPLACE VIEW combined_orders AS
SELECT * FROM orders
UNION ALL
SELECT * FROM orders_new;

-- verificar se a view está ok
select * from combined_orders;


-- agora cria uma função e trigger para sincronizar a atualização.
BEGIN;


-- Função de sincronização completa
CREATE OR REPLACE FUNCTION sync_to_partitions()
RETURNS TRIGGER AS $$
BEGIN
    -- Tratamento de INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO orders_new (id, product_name, quantity, order_date)
        VALUES (NEW.id, NEW.product_name, NEW.quantity, NEW.order_date)
        ON CONFLICT (id, order_date) DO UPDATE
        SET product_name = EXCLUDED.product_name,
            order_date = EXCLUDED.order_date,
            quantity = EXCLUDED.quantity;

-- Tratamento de UPDATE
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE orders_new
        SET product_name = NEW.product_name,
            order_date = NEW.order_date,
            quantity = NEW.quantity
        WHERE id = OLD.id;

    -- Tratamento de DELETE
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM orders_new WHERE id = OLD.id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para manter sincronização em tempo real
CREATE TRIGGER sync_orders_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION sync_to_partitions();

COMMIT;

-- faço a migração da orders para a orders_new dos dados já existentes para a tabela particionada.
-- Migrar em lotes para evitar bloqueios
DO $$
DECLARE
    batch_size INT := 10000;
    last_id INT := 0;
BEGIN
    LOOP
        -- Inserir apenas registros que ainda não estão na tabela particionada
        INSERT INTO orders_new (id, product_name, quantity, order_date)
        SELECT o.id, o.product_name, o.quantity, o.order_date
        FROM orders o
        LEFT JOIN orders_new on (o.id = orders_new.id AND o.order_date = orders_new.order_date)
        WHERE orders_new.id IS NULL
        AND o.id > last_id
        ORDER BY o.id
        LIMIT batch_size;

        -- Atualizar o último ID processado na tabela original orders
        SELECT COALESCE(MAX(id), 0) INTO last_id
        FROM orders
        WHERE id <= (SELECT MAX(id) FROM orders_new);

        -- Sair se não houver mais registros a migrar
        EXIT WHEN last_id = (SELECT MAX(id) FROM orders);
    END LOOP;
END $$;

-- verifica a atualização da orders_new com os dados.
select * from orders_new order by id


-- numa unica transação, faz a alteração do nome da tabela orders para a particioanda e desativa a trigger. 
-- optei por não deletar a orders_old para uma eventual conferência.
BEGIN;

-- Renomear as tabelas
ALTER TABLE orders RENAME TO orders_old;
ALTER TABLE orders_new RENAME TO orders;

-- Desativar o trigger temporário
DROP TRIGGER IF EXISTS sync_orders_trigger ON orders;

COMMIT;

select count(*) from orders;
