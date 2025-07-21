# Простой скрипт для управления контейнером API подбрасывания монетки

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "test")]
    [string]$Action = "status"
)

$ContainerName = "coin-flip-container"
$ImageName = "coin-flip-api"

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Start-Container {
    Write-Status "Запуск контейнера $ContainerName..."
    docker run -d -p 8000:8000 --name $ContainerName $ImageName
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Контейнер успешно запущен!" "Green"
        Write-Status "API доступен по адресу: http://localhost:8000" "Cyan"
        Write-Status "Документация: http://localhost:8000/docs" "Cyan"
    } else {
        Write-Status "Ошибка при запуске контейнера!" "Red"
    }
}

function Stop-Container {
    Write-Status "Остановка контейнера $ContainerName..."
    docker stop $ContainerName
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Контейнер остановлен!" "Yellow"
    } else {
        Write-Status "Ошибка при остановке контейнера!" "Red"
    }
}

function Remove-Container {
    Write-Status "Удаление контейнера $ContainerName..."
    docker rm $ContainerName 2>$null
}

function Show-Status {
    Write-Status "Статус контейнеров:" "Cyan"
    docker ps -a --filter "name=$ContainerName"
}

function Show-Logs {
    Write-Status "Логи контейнера $ContainerName:" "Cyan"
    docker logs $ContainerName
}

function Test-API {
    Write-Status "Тестирование API..." "Cyan"
    
    try {
        # Тест корневого эндпоинта
        Write-Status "Тест 1: Корневой эндпоинт" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost:8000/" -Method GET
        Write-Host "Ответ получен успешно" -ForegroundColor Gray
        
        # Тест подбрасывания один раз
        Write-Status "Тест 2: Подбрасывание один раз" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost:8000/flip" -Method GET
        Write-Host "Результат: $($response.результат)" -ForegroundColor Gray
        
        # Тест подбрасывания несколько раз
        Write-Status "Тест 3: Подбрасывание 5 раз" "Yellow"
        $body = '{"количество": 5}'
        $response = Invoke-RestMethod -Uri "http://localhost:8000/flip" -Method POST -Body $body -ContentType "application/json"
        Write-Host "Подброшено: $($response.статистика.всего_подбрасываний) раз" -ForegroundColor Gray
        
        # Тест статистики
        Write-Status "Тест 4: Статистика" "Yellow"
        $response = Invoke-RestMethod -Uri "http://localhost:8000/stats" -Method GET
        Write-Host "Статистика получена" -ForegroundColor Gray
        
        Write-Status "Все тесты прошли успешно!" "Green"
        
    } catch {
        Write-Status "Ошибка при тестировании API: $($_.Exception.Message)" "Red"
    }
}

# Основная логика
switch ($Action) {
    "start" {
        # Проверяем, существует ли контейнер
        $existing = docker ps -a --filter "name=$ContainerName" --format "table {{.Names}}" | Select-String $ContainerName
        if ($existing) {
            Write-Status "Контейнер уже существует. Перезапускаю..." "Yellow"
            Stop-Container
            Remove-Container
        }
        Start-Container
    }
    "stop" {
        Stop-Container
    }
    "restart" {
        Stop-Container
        Remove-Container
        Start-Container
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
    default {
        Write-Status "Неизвестное действие: $Action" "Red"
        Write-Status "Доступные действия: start, stop, restart, logs, status, test" "Yellow"
    }
} 