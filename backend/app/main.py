# app/main.py
from fastapi import FastAPI
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.core.logging import setup_logging
from app.db.session import SessionLocal
from app.crud.symbol import symbol_crud
from app.api.api import api_router
from app.db.base_class import Base
from app.db.session import engine

setup_logging()

app = FastAPI()

Base.metadata.create_all(bind=engine)

scheduler = BackgroundScheduler(timezone="UTC")

def run_kirakira_decay():
    db = SessionLocal()
    try:
        symbol_crud.decay_kirakira_levels(db)
    finally:
        db.close()

@app.on_event("startup")
def start_scheduler():
    scheduler.add_job(
        run_kirakira_decay,
        IntervalTrigger(minutes=10),
        id="kirakira_decay",
        replace_existing=True,
    )
    scheduler.start()

@app.on_event("shutdown")
def stop_scheduler():
    scheduler.shutdown(wait=False)

app.include_router(api_router)