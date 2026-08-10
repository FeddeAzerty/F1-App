from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import circuits, constructors, drivers, news, races, standings

app = FastAPI(
    title="F1 Portfolio API",
    description="Race schedule, results, and standings backed by the Jolpica F1 API.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(races.router)
app.include_router(standings.router)
app.include_router(drivers.router)
app.include_router(constructors.router)
app.include_router(circuits.router)
app.include_router(news.router)

@app.get("/api/health")
def health_check():
    return {"status": "ok"}
