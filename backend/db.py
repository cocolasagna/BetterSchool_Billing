from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DB_USER = "postgres"
DB_PASS = ""  # fill in if needed
DB_NAME = "betterschool_billing"
DB_HOST = "localhost"
DB_PORT = "5432"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
