# Скрипт для управления контейнерами nginx + API

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "test", "build")]
    [string]$Action = "status"
)

$ProjectName = "coin-flip"

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Start-Containers {
    Write-Status "Запуск контейнеров nginx + API..."
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Контейнеры успешно запущены!" "Green"
        Write-Status "Фронтенд доступен по адресу: http://localhost" "Cyan"
        Write-Status "API доступен по адресу: http://localhost/api" "Cyan"
        Write-Status "Документация: http://localhost/docs" "Cyan"
    } else {
        Write-Status "Ошибка при запуске контейнеров!" "Red"
    }
}

function Stop-Containers {
    Write-Status "Остановка контейнеров..."
    docker-compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Контейнеры остановлены!" "Yellow"
    } else {
        Write-Status "Ошибка при остановке контейнеров!" "Red"
    }
}

function Show-Status {
    Write-Status "Статус контейнеров:" "Cyan"
    docker-compose ps
}

function Show-Logs {
    Write-Status "Логи контейнеров:" "Cyan"
    docker-compose logs
}

function Build-Containers {
    Write-Status "Сборка контейнеров..." "Yellow"
    docker-compose build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Контейнеры успешно собраны!" "Green"
    } else {
        Write-Status "Ошибка при сборке контейнеров!" "Red"
    }
}

function Test-API {
    Write-Status "Тестирование API через nginx..." "Cyan"
    
    try {
        # Тест корневого эндпоинта
        Write-Status "Тест 1: Корневой эндпоинт" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost/" -Method GET
        Write-Host "Ответ получен успешно" -ForegroundColor Gray
        
        # Тест подбрасывания один раз
        Write-Status "Тест 2: Подбрасывание один раз" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost/flip" -Method GET
        Write-Host "Результат: $($response.результат)" -ForegroundColor Gray
        
        # Тест подбрасывания несколько раз
        Write-Status "Тест 3: Подбрасывание 5 раз" "Yellow"
        $body = '{"количество": 5}'
        $response = Invoke-RestMethod -Uri "http://localhost/flip" -Method POST -Body $body -ContentType "application/json"
        Write-Host "Подброшено: $($response.статистика.всего_подбрасываний) раз" -ForegroundColor Gray
        
        # Тест статистики
        Write-Status "Тест 4: Статистика" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost/stats" -Method GET
        Write-Host "Статистика получена" -ForegroundColor Gray
        
        Write-Status "Все тесты прошли успешно!" "Green"
        
    } catch {
        Write-Status "Ошибка при тестировании API: $($_.Exception.Message)" "Red"
    }
}

# Основная логика
switch ($Action) {
    "start" {
        Start-Containers
    }
    "stop" {
        Stop-Containers
    }
    "restart" {
        Stop-Containers
        Start-Containers
    }
    "logs" {
        Show-Logs
    }
    "status" {
        Show-Status
    }
    "test" {
        Test-API
    }
    "build" {
        Build-Containers
    }
    default {
        Write-Status "Неизвестное действие: $Action" "Red"
        Write-Status "Доступные действия: start, stop, restart, logs, status, test, build" "Yellow"
    }
} 