import psycopg2
import os
import pathlib

DB_NAME = 'betterschool_billing'
USER = 'postgres'
PASSWORD = os.getenv('PGPASSWORD')  # From batch
HOST = 'localhost'
PORT = '5432'

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

        # Path to init.sql
        init_sql_path = pathlib.Path(__file__).resolve().parent.parent / 'init_db' / 'init.sql'

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
        exit(1)  # So batch script knows to retry

if __name__ == '__main__':
    if not db_exists():
        print(f"Database '{DB_NAME}' does not exist. Creating it now...")
        create_db_and_tables()
    else:
        print(f"Database '{DB_NAME}' already exists.")
