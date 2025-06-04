from typing import List
from fastapi import FastAPI, APIRouter, Request, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import os

from pydantic import BaseModel
from models import User as DBUser
from database import engine, SessionLocal, Base

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve React static files
app.mount("/static", StaticFiles(directory="../frontend/build/static"), name="static")

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class UserCreate(BaseModel):
    username: str
    password_hash: str

class UserRead(BaseModel):
    id: int
    username: str
    password_hash: str

    class Config:
        orm_mode = True

# Router
api_router = APIRouter(prefix="/api")

@api_router.get("/hello")
async def api_hello():
    return {"message": "Hello from FastAPI!"}

@api_router.get("/users", response_model=List[UserRead])
def get_users(db: Session = Depends(get_db)):
    return db.query(DBUser).all()

@api_router.post("/users", response_model=UserRead)
def add_user(user: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(DBUser).filter(DBUser.username == user.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")

    db_user = DBUser(username=user.username, password_hash=user.password_hash)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# Register API
app.include_router(api_router)

# Fallback to React app
@app.get("/{full_path:path}")
async def serve_react_app(request: Request, full_path: str):
    if request.url.path.startswith("/api/"):
        return JSONResponse({"error": "API endpoint not found"}, status_code=404)

    index_path = os.path.abspath("../frontend/build/index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path, media_type="text/html")
    else:
        return JSONResponse({"error": "React frontend not found"}, status_code=500)
