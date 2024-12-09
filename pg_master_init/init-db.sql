\c cloudwalkdb;

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product_name TEXT,
    quantity INT,
    order_date DATE
);

CREATE PUBLICATION orderspub FOR TABLE orders;