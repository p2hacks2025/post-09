# app/core/timezone.py
from datetime import datetime, date, time, timedelta
from zoneinfo import ZoneInfo

JST = ZoneInfo("Asia/Tokyo")
UTC = ZoneInfo("UTC")

def utc_now() -> datetime:
    return datetime.now(UTC)

def ensure_tz(dt: datetime, assume_tz=UTC) -> datetime:
    """naiveなら assume_tz を付与、awareならそのまま返す"""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=assume_tz)
    return dt

def to_jst(dt: datetime) -> datetime:
    dt = ensure_tz(dt, assume_tz=UTC)
    return dt.astimezone(JST)

def to_utc(dt: datetime) -> datetime:
    dt = ensure_tz(dt, assume_tz=UTC)
    return dt.astimezone(UTC)

def jst_day_to_utc_range(d: date) -> tuple[datetime, datetime]:
    start_jst = datetime.combine(d, time.min).replace(tzinfo=JST)
    end_jst = start_jst + timedelta(days=1)
    return start_jst.astimezone(UTC), end_jst.astimezone(UTC)
