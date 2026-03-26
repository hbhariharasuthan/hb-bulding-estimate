# -------------------------
# Backend Dockerfile (CPU / Apple Silicon friendly)
# -------------------------

    FROM python:3.11-slim

    WORKDIR /app
    
    # -------------------------
    # System Dependencies
    # -------------------------
    RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libpq-dev \           
        libgl1 \
        libglib2.0-0 \        
        tesseract-ocr \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    # -------------------------
    # Python Dependencies
    # -------------------------
    COPY requirements.txt .
    
    RUN pip install --upgrade pip
    
    # Prevent cache issues
    RUN pip install --no-cache-dir -r requirements.txt
    
    # -------------------------
    # Copy Application Code
    # -------------------------
    COPY ./app/ ./app/

    # -------------------------
    # Copy Alembic migrations
    # -------------------------
    COPY ./alembic.ini ./alembic.ini
    COPY ./alembic/ ./alembic/
    
    # -------------------------
    # Environment Variables
    # -------------------------
    ENV PYTHONUNBUFFERED=1
    
    # -------------------------
    # Expose Port
    # -------------------------
    EXPOSE 8000
    
    # -------------------------
    # Start FastAPI
    # -------------------------
    CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
    