from fastapi import APIRouter

from app.schemas.news import NewsArticleOut
from app.services.news.client import fetch_f1_news

router = APIRouter(prefix="/api/news", tags=["news"])

@router.get("", response_model=list[NewsArticleOut])
def list_news():
    return fetch_f1_news()
