from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Constructor(Base):
    __tablename__ = "constructors"

    id: Mapped[int] = mapped_column(primary_key=True)
    constructor_ref: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    nationality: Mapped[str | None] = mapped_column(String(128), nullable=True)
    url: Mapped[str | None] = mapped_column(String(512), nullable=True)
