import random
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import psycopg2
import os

app = FastAPI(
    title="API для подбрасывания монетки",
    description="Простое API для симуляции подбрасывания монетки",
    version="1.0.0"
)

# Монтируем статические файлы
app.mount("/static", StaticFiles(directory="static"), name="static")

class CoinFlipRequest(BaseModel):
    """Модель запроса для подбрасывания монетки"""
    количество: int = 1
    сторона: Optional[str] = None  # "орёл" или "решка"

class CoinFlipResponse(BaseModel):
    """Модель ответа с результатами подбрасывания"""
    результаты: List[str]
    статистика: dict
    сообщение: str

def сохранить_результат_в_базу(результат, количество):
    """Сохраняет результат броска монетки в таблицу coin_flip_stats на alwaysdata.net"""
    try:
        conn = psycopg2.connect(
            dbname="julika_test",
            user="julika_admin",
            password="3198692z",
            host="postgresql-julika.alwaysdata.net",
            port=5432
        )
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO coin_flip_stats (результат, количество) VALUES (%s, %s)",
            (результат, количество)
        )
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Ошибка при сохранении результата в базу данных: {e}")

@app.get("/", response_class=HTMLResponse)
async def главная_страница():
    """Главная страница с веб-интерфейсом для подбрасывания монетки"""
    try:
        with open("templates/index.html", "r", encoding="utf-8") as file:
            html_content = file.read()
        return HTMLResponse(content=html_content, status_code=200)
    except FileNotFoundError:
        return HTMLResponse(
            content="<h1>Ошибка: файл интерфейса не найден</h1>", 
            status_code=404
        )

@app.get("/flip")
async def подбросить_монетку():
    """Подбросить монетку один раз и записать результат в базу данных"""
    результат = random.choice(["орёл", "решка"])
    сохранить_результат_в_базу(результат, 1)
    return {
        "результат": результат,
        "сообщение": f"Монетка показала: {результат}"
    }

@app.post("/flip", response_model=CoinFlipResponse)
async def подбросить_монетку_несколько_раз(запрос: CoinFlipRequest):
    """Подбросить монетку указанное количество раз и записать результаты в базу данных"""
    if запрос.количество <= 0:
        raise HTTPException(status_code=400, detail="Количество должно быть больше 0")
    
    if запрос.количество > 100:
        raise HTTPException(status_code=400, detail="Максимальное количество подбрасываний: 100")
    
    результаты = []
    for _ in range(запрос.количество):
        результат = random.choice(["орёл", "решка"])
        результаты.append(результат)
        сохранить_результат_в_базу(результат, 1)
    
    # Подсчёт статистики
    орёл_количество = результаты.count("орёл")
    решка_количество = результаты.count("решка")
    
    статистика = {
        "всего_подбрасываний": запрос.количество,
        "орёл": {
            "количество": орёл_количество,
            "процент": round((орёл_количество / запрос.количество) * 100, 2)
        },
        "решка": {
            "количество": решка_количество,
            "процент": round((решка_количество / запрос.количество) * 100, 2)
        }
    }
    
    сообщение = f"Подброшено {запрос.количество} раз(а). Орёл: {орёл_количество}, Решка: {решка_количество}"
    
    return CoinFlipResponse(
        результаты=результаты,
        статистика=статистика,
        сообщение=сообщение
    )

@app.get("/stats")
async def получить_статистику():
    """Получить общую статистику подбрасываний"""
    return {
        "статистика": {
            "всего_подбрасываний": "Неограниченно",
            "возможные_результаты": ["орёл", "решка"],
            "вероятность_каждой_стороны": "50%",
            "описание": "Случайное подбрасывание с равной вероятностью для каждой стороны"
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 