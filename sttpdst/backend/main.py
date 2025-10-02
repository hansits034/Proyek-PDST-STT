from fastapi import FastAPI, File, UploadFile
import shutil
import os

app = FastAPI()

# Folder untuk menyimpan file upload
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.get("/")
async def root():
    return {"message": "Backend is running"}

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """
    Endpoint untuk menerima file audio dari Flutter
    """
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return {"filename": file.filename, "path": file_path}

@app.get("/files")
async def list_files():
    """
    Menampilkan daftar file yang sudah di-upload
    """
    files = os.listdir(UPLOAD_DIR)
    return {"files": files}

@app.get("/files/{filename}")
async def get_file(filename: str):
    """
    Mengecek apakah file tertentu ada di server
    """
    file_path = os.path.join(UPLOAD_DIR, filename)
    if os.path.exists(file_path):
        return {"path": file_path}
    return {"error": "File not found"}
