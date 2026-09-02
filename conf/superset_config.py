import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "lab-only")
SQLALCHEMY_DATABASE_URI = (
    f"postgresql+psycopg2://{os.environ['DATABASE_USER']}:{os.environ['DATABASE_PASSWORD']}"
    f"@{os.environ['DATABASE_HOST']}:{os.environ['DATABASE_PORT']}/{os.environ['DATABASE_DB']}"
)

REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = os.environ.get("REDIS_PORT", "6379")

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_DB": 1,
}
DATA_CACHE_CONFIG = dict(CACHE_CONFIG, CACHE_REDIS_DB=2)

FEATURE_FLAGS = {"DASHBOARD_RBAC": True}
TALISMAN_ENABLED = False
WTF_CSRF_ENABLED = False
