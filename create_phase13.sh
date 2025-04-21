#!/usr/bin/env bash
set -euo pipefail

echo "➡️ Adding authentication dependencies..."
if command -v poetry &>/dev/null; then
  poetry add passlib[bcrypt] python-jose[cryptography] --quiet
else
  pip install passlib[bcrypt] python-jose[cryptography]
fi

echo "➡️ Writing core/auth.py..."
mkdir -p backend/core
cat > backend/core/auth.py <<'PY'
"""
backend/core/auth.py
--------------------
JWT-based authentication and authorization for FastAPI.
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.config import settings
from backend.db.database import get_db
from backend.db.models import User

# Constants
SECRET_KEY = settings.jwt_secret
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalars().first()

async def authenticate_user(db: AsyncSession, email: str, password: str) -> Optional[User]:
    user = await get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = await get_user_by_email(db, email)  # type: ignore
    if user is None:
        raise credentials_exception
    return user  # type: ignore

async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")
    return current_user  # type: ignore
PY

echo "➡️ Writing routers/auth.py..."
mkdir -p backend/routers
cat > backend/routers/auth.py <<'PY'
"""
backend/routers/auth.py
-----------------------
Authentication & registration endpoints.
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, Field

from backend.core.auth import (
    get_password_hash,
    authenticate_user,
    create_access_token,
    get_current_active_user,
)
from backend.db.database import DBSessionDep
from backend.db.models import User

router = APIRouter()

class UserCreate(BaseModel):
    email: str = Field(..., example="you@example.com")
    password: str = Field(..., min_length=8)

class UserOut(BaseModel):
    id: UUID
    email: str
    is_active: bool

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(user_in: UserCreate, db: DBSessionDep):
    exists = await db.execute(select(User).where(User.email == user_in.email))
    if exists.scalars().first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    user = User(email=user_in.email, hashed_password=get_password_hash(user_in.password))
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user

@router.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: DBSessionDep):
    user = await authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserOut)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    return current_user
PY

echo "➡️ Patching backend/app.py to include auth router..."
cat > /tmp/app.py.patch <<'PATCH'
--- backend/app.py
+++ backend/app.py
@@ -1,3 +1,7 @@
 def create_app() -> FastAPI:
-    # Mount routers
+    # Mount auth router
+    from backend.routers.auth import router as auth_router
+    app.include_router(auth_router, prefix="/auth", tags=["auth"])
+
+    # Mount routers
PATCH
patch -p0 < /tmp/app.py.patch || true

echo "➡️ Securing project endpoints..."
cat > /tmp/projects.py.patch1 <<'PATCH'
--- backend/routers/projects.py
+++ backend/routers/projects.py
@@ -1,1 +1,1 @@
-from fastapi import APIRouter, HTTPException, status, Depends
+from fastapi import APIRouter, HTTPException, status, Depends
@@ -1,1 +1,2 @@
-from backend.db.database import get_db, DBSessionDep
+from backend.db.database import get_db, DBSessionDep
+from backend.core.auth import get_current_active_user
+from backend.db.models import User as DBUser
PATCH
patch -p0 < /tmp/projects.py.patch1 || true

# Update create_project
cat > /tmp/projects.py.patch2 <<'PATCH'
--- backend/routers/projects.py
+++ backend/routers/projects.py
@@ -1,4 +1,5 @@
-@router.post("/", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
-async def create_project(
-    body: ProjectCreate, db: DBSessionDep
-):
-    owner_id = body.owner_id or UUID("00000000-0000-0000-0000-000000000001")
+@router.post("/", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
+async def create_project(
+    body: ProjectCreate,
+    db: DBSessionDep,
+    current_user: DBUser = Depends(get_current_active_user),
+):
+    owner_id = current_user.id
PATCH
patch -p0 < /tmp/projects.py.patch2 || true

# Update list_projects
cat > /tmp/projects.py.patch3 <<'PATCH'
--- backend/routers/projects.py
+++ backend/routers/projects.py
@@ -1,3 +1,6 @@
-@router.get("/", response_model=list[ProjectOut])
-async def list_projects(db: DBSessionDep):
-    result = await db.execute(select(models.Project))
-    return result.scalars().all()
+@router.get("/", response_model=list[ProjectOut])
+async def list_projects(
+    db: DBSessionDep,
+    current_user: DBUser = Depends(get_current_active_user),
+):
+    result = await db.execute(
+        select(models.Project).where(models.Project.owner_id == current_user.id)
+    )
+    return result.scalars().all()
PATCH
patch -p0 < /tmp/projects.py.patch3 || true

# Update get_project
cat > /tmp/projects.py.patch4 <<'PATCH'
--- backend/routers/projects.py
+++ backend/routers/projects.py
@@ -1,5 +1,8 @@
-async def get_project(project_id: UUID, db: DBSessionDep):
-    proj = await db.get(models.Project, project_id)
-    if not proj:
-        raise HTTPException(status_code=404, detail="Project not found")
-    return proj
+async def get_project(
+    project_id: UUID,
+    db: DBSessionDep,
+    current_user: DBUser = Depends(get_current_active_user),
+):
+    proj = await db.get(models.Project, project_id)
+    if not proj or proj.owner_id != current_user.id:
+        raise HTTPException(status_code=404, detail="Project not found")
+    return proj
PATCH
patch -p0 < /tmp/projects.py.patch4 || true

# Update delete_project
cat > /tmp/projects.py.patch5 <<'PATCH'
--- backend/routers/projects.py
+++ backend/routers/projects.py
@@ -1,3 +1,8 @@
-async def delete_project(project_id: UUID, db: DBSessionDep):
-    await db.execute(delete(models.Project).where(models.Project.id == project_id))
-    await db.commit()
+async def delete_project(
+    project_id: UUID,
+    db: DBSessionDep,
+    current_user: DBUser = Depends(get_current_active_user),
+):
+    proj = await db.get(models.Project, project_id)
+    if not proj or proj.owner_id != current_user.id:
+        raise HTTPException(status_code=404, detail="Project not found")
+    await db.execute(delete(models.Project).where(models.Project.id == project_id))
+    await db.commit()
PATCH
patch -p0 < /tmp/projects.py.patch5 || true

echo "➡️ Securing file upload endpoint..."
cat > /tmp/files.py.patch1 <<'PATCH'
--- backend/routers/files.py
+++ backend/routers/files.py
@@ -1,1 +1,1 @@
-from fastapi import APIRouter, UploadFile, File, HTTPException, status
+from fastapi import APIRouter, UploadFile, File, HTTPException, status, Depends
@@ -1,1 +1,2 @@
-from backend.db.database import DBSessionDep
+from backend.db.database import DBSessionDep
+from backend.core.auth import get_current_active_user
+from backend.db.models import User as DBUser
PATCH
patch -p0 < /tmp/files.py.patch1 || true

# Update upload_pdf signature and permission check
cat > /tmp/files.py.patch2 <<'PATCH'
--- backend/routers/files.py
+++ backend/routers/files.py
@@ -1,5 +1,6 @@
-async def upload_pdf(
-    project_id: UUID,
-    pdf: UploadFile = File(...),
-    db: DBSessionDep,
-):
+async def upload_pdf(
+    project_id: UUID,
+    pdf: UploadFile = File(...),
+    db: DBSessionDep,
+    current_user: DBUser = Depends(get_current_active_user),
+):
@@ -1,3 +1,3 @@
-    project = await db.get(models.Project, project_id)
-    if not project or project.owner_id != current_user.id:
-        raise HTTPException(status_code=404, detail="Project not found")
+    project = await db.get(models.Project, project_id)
+    if not project or project.owner_id != current_user.id:
+        raise HTTPException(status_code=403, detail="Not authorized to upload to this project")
PATCH
patch -p0 < /tmp/files.py.patch2 || true

echo "➡️ Patching config.py to add JWT secret..."
cat > /tmp/config.py.patch <<'PATCH'
--- backend/config.py
+++ backend/config.py
@@ -1,3 +1,5 @@
 class Settings(BaseSettings):
+    # JWT configuration
+    jwt_secret: str = "CHANGE_THIS_TO_A_STRONG_SECRET_IN_PRODUCTION"
PATCH
patch -p0 < /tmp/config.py.patch || true

echo "✅ Phase 13 complete: Authentication & basic access control added."
