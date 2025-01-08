from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
from io import BytesIO
import subprocess
import os

app = FastAPI()
UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("output")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)
libreoffice_path = "C:\Program Files\LibreOffice\program\soffice.exe"


def convert_with_libreoffice(input_file: Path, output_file: Path):
    # 使用 LibreOffice 進行高精度轉換
    # --headless 讓 LibreOffice 在沒有 GUI 的情況下運行
    # --convert-to pdf 指定轉換為 PDF 格式
    subprocess.run([
        libreoffice_path, "--headless", "--convert-to", "pdf", "--outdir", str(OUTPUT_DIR), str(input_file)
    ], check=True)

@app.post("/convert")
async def convert_file_to_pdf(file: UploadFile):

    for fileInServer in os.listdir(UPLOAD_DIR):
        os.remove(UPLOAD_DIR/fileInServer)

    for fileInServer in os.listdir(OUTPUT_DIR):
        os.remove(OUTPUT_DIR/fileInServer)

    input_file = UPLOAD_DIR / file.filename
    with open(input_file, "wb") as f:
        f.write(await file.read())

    output_file = OUTPUT_DIR / f"{input_file.stem}.pdf"
    convert_with_libreoffice(input_file, output_file)

    return FileResponse(output_file, media_type="application/pdf", filename=output_file.name)


@app.get("/")
def root():
    return {"message": "Welcome to the file conversion API. Use /convert"}
