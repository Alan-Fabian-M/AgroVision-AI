from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError


class DatabaseException(Exception):
    def __init__(self, detail: str = "Database error occurred"):
        self.detail = detail
        super().__init__(self.detail)


class NotFoundException(Exception):
    def __init__(self, detail: str = "Resource not found"):
        self.detail = detail
        super().__init__(self.detail)


async def database_exception_handler(request: Request, exc: DatabaseException):
    return JSONResponse(
        status_code=500,
        content={"detail": f"Database error: {exc.detail}"}
    )


async def not_found_exception_handler(request: Request, exc: NotFoundException):
    return JSONResponse(
        status_code=404,
        content={"detail": exc.detail}
    )


async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    return JSONResponse(
        status_code=500,
        content={"detail": "An error occurred while processing your request"}
    )
