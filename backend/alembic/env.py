from logging.config import fileConfig
import os

from sqlalchemy import create_engine
from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
from app.models import Base

target_metadata = Base.metadata

# Optional: create one table per migration by filtering objects during
# `alembic revision --autogenerate ...`.
#
# Usage (table-by-table autogenerate):
#   docker exec -e ALEMBIC_TABLES=users backend python -m alembic revision --autogenerate -m "create_users"
#
# When `ALEMBIC_TABLES` is omitted, Alembic behaves normally (generates all diffs).
def _tables_to_include() -> set[str] | None:
    raw = os.environ.get("ALEMBIC_TABLES")
    if not raw or not raw.strip():
        return None
    return {t.strip() for t in raw.split(",") if t.strip()}


def _include_object(obj, name, type_, reflected, compare_to) -> bool:
    tables = _tables_to_include()
    if not tables:
        return True

    if type_ == "table":
        return name in tables

    # For columns/constraints/indexes/foreign keys, `obj.table.name` is the table.
    table = getattr(obj, "table", None)
    table_name = getattr(table, "name", None)
    if table_name:
        return table_name in tables

    return True

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    url = os.environ.get("DATABASE_URL") or config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        include_object=_include_object,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    db_url = os.environ.get("DATABASE_URL")
    if db_url:
        connectable = create_engine(db_url, poolclass=pool.NullPool)
    else:
        connectable = engine_from_config(
            config.get_section(config.config_ini_section, {}),
            prefix="sqlalchemy.",
            poolclass=pool.NullPool,
        )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            include_object=_include_object,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
