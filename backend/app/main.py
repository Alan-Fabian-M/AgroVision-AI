from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import get_settings
from app.core.database import engine, Base
from app.core.neo4j import close_driver
from app.core.exceptions import (
    DatabaseException,
    NotFoundException,
    database_exception_handler,
    not_found_exception_handler,
    sqlalchemy_exception_handler,
)
from app.routers.diagnostics import router as diagnostics_router
from app.routers.knowledge import router as knowledge_router
from app.routers.analyze import router as analyze_router
from sqlalchemy.exc import SQLAlchemyError

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield
    await close_driver()


app = FastAPI(
    title=settings.PROJECT_NAME,
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(DatabaseException, database_exception_handler)
app.add_exception_handler(NotFoundException, not_found_exception_handler)
app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)

app.include_router(diagnostics_router, prefix=settings.API_V1_PREFIX)
app.include_router(knowledge_router, prefix=settings.API_V1_PREFIX)
app.include_router(analyze_router, prefix=settings.API_V1_PREFIX)


@app.get("/health")
def health_check():
    return {"status": "healthy"}
