# Архитектура с Nginx + API

## Описание

Проект теперь использует двухконтейнерную архитектуру:
- **Nginx контейнер** - обслуживает статические файлы и проксирует API запросы
- **API контейнер** - FastAPI приложение для подбрасывания монетки

## Структура проекта

```
coin-flip-api/
├── main.py              # API приложение (FastAPI)
├── requirements.txt     # Зависимости Python
├── Dockerfile          # Контейнер для API
├── nginx/
│   ├── Dockerfile      # Контейнер для Nginx
│   ├── nginx.conf      # Конфигурация Nginx
│   └── static/         # Статические файлы (HTML, CSS, JS)
├── docker-compose.yml  # Оркестрация контейнеров
├── manage-nginx.ps1    # Скрипт управления
└── README-NGINX.md     # Эта документация
```

## Преимущества новой архитектуры

1. **Разделение ответственности** - Nginx для статики, API для логики
2. **Лучшая производительность** - Nginx оптимизирован для статических файлов
3. **Масштабируемость** - можно легко добавить больше API контейнеров
4. **Безопасность** - API не доступен напрямую извне
5. **Кэширование** - Nginx кэширует статические файлы

## Запуск

### Использование скрипта управления

```powershell
# Собрать контейнеры
.\manage-nginx.ps1 build

# Запустить контейнеры
.\manage-nginx.ps1 start

# Проверить статус
.\manage-nginx.ps1 status

# Протестировать API
.\manage-nginx.ps1 test

# Остановить контейнеры
.\manage-nginx.ps1 stop

# Перезапустить
.\manage-nginx.ps1 restart

# Показать логи
.\manage-nginx.ps1 logs
```

### Использование Docker Compose

```bash
# Запустить
docker-compose up -d

# Остановить
docker-compose down

# Показать логи
docker-compose logs

# Пересобрать
docker-compose build --no-cache
```

## Доступные адреса

- **Фронтенд**: `http://localhost` - веб-интерфейс
- **API информация**: `http://localhost/api` - информация об API
- **Документация**: `http://localhost/docs` - Swagger UI
- **Подбрасывание**: `http://localhost/flip` - API эндпоинт
- **Статистика**: `http://localhost/stats` - API эндпоинт

## Конфигурация Nginx

Nginx настроен для:
- Обслуживания статических файлов из `/usr/share/nginx/html/`
- Проксирования API запросов к контейнеру API
- Кэширования статических файлов
- Логирования запросов

## Сеть

Контейнеры подключены к внутренней сети `coin-flip-network`:
- API доступен внутри сети по адресу `http://api:8000`
- Nginx проксирует запросы к API
- Внешний доступ только через порт 80 (Nginx)

## Мониторинг

### Проверка статуса контейнеров
```powershell
docker-compose ps
```

### Просмотр логов
```powershell
# Все контейнеры
docker-compose logs

# Только API
docker-compose logs api

# Только Nginx
docker-compose logs nginx
```

### Проверка сети
```powershell
docker network ls
docker network inspect coin-flip-api_coin-flip-network
```

## Устранение неполадок

### Контейнеры не запускаются
1. Проверьте, что Docker Desktop запущен
2. Проверьте логи: `docker-compose logs`
3. Убедитесь, что порт 80 свободен

### API не отвечает
1. Проверьте статус контейнеров: `docker-compose ps`
2. Проверьте логи API: `docker-compose logs api`
3. Проверьте логи Nginx: `docker-compose logs nginx`

### Статические файлы не загружаются
1. Проверьте, что папка `nginx/static/` существует
2. Пересоберите контейнеры: `docker-compose build --no-cache`

## Производительность

- **Nginx** обрабатывает статические файлы очень быстро
- **API** работает только для динамических запросов
- **Кэширование** статических файлов в браузере
- **Сжатие** ответов Nginx

## Безопасность

- API не доступен напрямую извне
- Все запросы проходят через Nginx
- Можно настроить SSL/TLS в Nginx
- Возможность добавления rate limiting 