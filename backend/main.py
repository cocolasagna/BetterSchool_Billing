from typing import List
from fastapi import FastAPI, APIRouter, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from pydantic import BaseModel

app = FastAPI()

# CORS middleware (adjust origins as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files from React build (adjust path to your build directory)
app.mount("/static", StaticFiles(directory="../frontend/build/static"), name="static")

# Pydantic model for User
class User(BaseModel):
    name: str
    email: str

# In-memory users list
users: List[User] = []

# Create API router
api_router = APIRouter(prefix="/api")

@api_router.get("/hello")
async def api_hello():
    return {"message": "Hello from FastAPI!"}

@api_router.get("/users", response_model=List[User])
def get_users():
    return users

@api_router.post("/users", response_model=User)
def add_user(user: User):
    users.append(user)
    return user

# Include API router in main app
app.include_router(api_router)

# Serve React index.html for all other non-API GET requests
@app.get("/{full_path:path}")
async def serve_react_app(request: Request, full_path: str):
    if request.url.path.startswith("/api/"):
        # If API route not matched, return 404 JSON
        return JSONResponse({"error": "API endpoint not found"}, status_code=404)

    index_path = os.path.abspath("../frontend/build/index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path, media_type="text/html")
    else:
        return JSONResponse({"error": "React frontend not found"}, status_code=500)
