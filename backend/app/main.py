from fastapi import FastAPI

from app.http import auth_router, plans_router

app = FastAPI(title="Building Estimate API")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def root():
    return {"message": "Building Estimate API"}


app.include_router(auth_router)
app.include_router(plans_router)
