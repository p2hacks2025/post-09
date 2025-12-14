# app/core/logging.py
import logging
import os
from logging.config import dictConfig

def setup_logging() -> None:
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    dictConfig(
        {
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {
                "default": {
                    "format": "%(asctime)s %(levelname)s [%(name)s] %(message)s",
                }
            },
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "formatter": "default",
                }
            },
            "root": {
                "level": log_level,
                "handlers": ["console"],
            },
            "loggers": {
                "uvicorn": {"level": log_level},
                "uvicorn.error": {"level": log_level},
                "uvicorn.access": {"level": log_level},
                "sqlalchemy.engine": {
                    "level": os.getenv("SQL_LOG_LEVEL", "WARNING").upper()
                },
            },
        }
    )
