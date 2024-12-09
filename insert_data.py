import psycopg2
from psycopg2.extras import execute_values
import random
import time
from datetime import date, timedelta

# Database connection parameters
conn = psycopg2.connect(
    dbname="cloudwalkdb",
    user="masteruser",
    password="masterpassword",
    host="pg_master",
    port="5432"
)

# List of sample product names
product_names = ["Laptop", "Smartphone", "Headphones", "Keyboard", "Monitor"]

# Function to generate a random date
def random_date(start_date, end_date):
    return start_date + timedelta(days=random.randint(0, (end_date - start_date).days))

try:
    while True:
        product_name = random.choice(product_names)
        quantity = random.randint(1, 100)
        order_date = random_date(date(2024, 1, 1), date(2024, 12, 31))
        
        insert_query = """
        INSERT INTO orders (product_name, quantity, order_date)
        VALUES (%s, %s, %s);
        """
        values = (product_name, quantity, order_date)
        
        with conn.cursor() as cur:
            cur.execute(insert_query, values)
            conn.commit()
        
        print(f"Inserted: {values}")
        
        time.sleep(10)

except KeyboardInterrupt:
    print("Script interrupted by user")

finally:
    conn.close()
