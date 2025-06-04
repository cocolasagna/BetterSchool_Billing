import psycopg2
import os
import pathlib

# Read DB connection info from environment variables with defaults
DB_NAME = os.getenv("PGDATABASE", "betterschool_billing")
USER = os.getenv("PGUSER", "postgres")
PASSWORD = os.getenv("PGPASSWORD", "")
HOST = os.getenv("PGHOST", "localhost")
PORT = os.getenv("PGPORT", "5433")  # Match your portable PG port

def db_exists():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=USER, password=PASSWORD, host=HOST, port=PORT)
        conn.close()
        return True
    except Exception as e:
        print(f"Database check error: {e}")
        return False

def create_db_and_tables():
    try:
        # Connect to default postgres DB to create target DB
        conn = psycopg2.connect(dbname='postgres', user=USER, password=PASSWORD, host=HOST, port=PORT)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute(f"SELECT 1 FROM pg_database WHERE datname = '{DB_NAME}'")
        exists = cursor.fetchone()

        if not exists:
            print(f"Creating database '{DB_NAME}'...")
            cursor.execute(f"CREATE DATABASE {DB_NAME}")
        cursor.close()
        conn.close()

        # Path to init.sql relative to this file
        init_sql_path = pathlib.Path(__file__).resolve().parent.parent / 'init_db' / 'init.sql'

        # Connect to newly created database and run init.sql
        conn = psycopg2.connect(dbname=DB_NAME, user=USER, password=PASSWORD, host=HOST, port=PORT)
        cursor = conn.cursor()
        with open(init_sql_path, 'r') as f:
            cursor.execute(f.read())
        conn.commit()
        cursor.close()
        conn.close()

        print(f"Database '{DB_NAME}' and tables created successfully.")
    except Exception as e:
        print(f"Error creating database or tables: {e}")
        exit(1)  # Signal failure to batch script for retry

if __name__ == '__main__':
    if not db_exists():
        print(f"Database '{DB_NAME}' does not exist. Creating it now...")
        create_db_and_tables()
    else:
        print(f"Database '{DB_NAME}' already exists.")
