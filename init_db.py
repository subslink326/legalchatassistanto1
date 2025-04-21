import asyncio
from backend.db.database import init_models

asyncio.run(init_models())
print("✅  Tables created successfully.")
