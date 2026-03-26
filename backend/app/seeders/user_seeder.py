from __future__ import annotations

from passlib.context import CryptContext

from app.db import SessionLocal
from app.models import User


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def seed_admin_user() -> None:
    session = SessionLocal()
    try:
        email = "admin@hbbe.com"
        plain_password = "password"

        user = session.query(User).filter(User.email == email).first()
        hashed = pwd_context.hash(plain_password)

        if user is None:
            user = User(
                name="HBBE Admin",
                email=email,
                hashed_password=hashed,
                role="admin",
                is_active=True,
                is_verified=True,
            )
            session.add(user)
        else:
            user.name = "HBBE Admin"
            user.hashed_password = hashed
            user.role = "admin"
            user.is_active = True
            user.is_verified = True

        session.commit()
        print("Admin user seeded: admin@hbbe.com")
    finally:
        session.close()


if __name__ == "__main__":
    seed_admin_user()

