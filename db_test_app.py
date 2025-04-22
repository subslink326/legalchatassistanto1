from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
import uvicorn

from backend.db.database import get_db

app = FastAPI(title="Database Test App")

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/db-test")
async def db_test(db: AsyncSession = Depends(get_db)):
    try:
        # Try to execute a simple query
        result = await db.execute("SELECT 1")
        value = result.scalar()
        return {"database_connection": "successful", "test_value": value}
    except Exception as e:
        return {"database_connection": "failed", "error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080)