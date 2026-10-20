# 7. Архитектура и диаграммы

Исходники диаграмм в формате Mermaid лежат в [diagrams/](../diagrams/) и редактируются текстом. Диаграммы ниже отображаются на GitHub и GitLab; для предзащиты нужно приложить экспорт в PNG или SVG (через mermaid.live или `mmdc`).

## 7.1. Контекстная диаграмма системы

См. [diagrams/context.mmd](../diagrams/context.mmd).

```mermaid
flowchart LR
    S[Студент] -->|игра, решения| APP[Мобильное приложение Flutter]
    T[Преподаватель] -->|Teacher Mode| APP
    A[Администратор] -->|управление контентом| APP
    APP -->|REST API / JSON, HTTPS| API[Серверная часть Node.js/Express]
    API --> DB[(PostgreSQL)]
    API -->|экспорт| CSV[Отчёты CSV]
```

## 7.2. Диаграмма вариантов использования

См. [diagrams/usecases.mmd](../diagrams/usecases.mmd).

```mermaid
flowchart TB
    subgraph Студент
      U1((Пройти сценарий))
      U2((Принять решение))
      U3((Посмотреть прогресс))
    end
    subgraph Преподаватель
      U4((Посмотреть статистику группы))
      U5((Экспорт отчёта CSV))
      U6((Назначить модуль))
    end
    subgraph Администратор
      U7((Управлять пользователями))
      U8((Управлять сценариями))
    end
    U1 --> U2
    U2 --> U3
```

## 7.3. Диаграмма компонентов (черновик)

См. [diagrams/components.mmd](../diagrams/components.mmd).

```mermaid
flowchart LR
    subgraph Client[Flutter-клиент]
      UI[UI / экраны]
      SM[State management]
      SE[Сценарный движок - отображение]
      HTTP[API-клиент]
      TS[Безопасное хранение токена]
    end
    subgraph Server[Node.js / Express]
      GW[Маршруты REST]
      AUTH[Аутентификация и RBAC]
      SIM[Сервис симуляции - расчёт последствий]
      SCN[Сервис сценариев]
      ANA[Аналитика и Teacher Mode]
      REP[Экспорт отчётов]
    end
    DB[(PostgreSQL)]
    UI --> SM --> SE
    SM --> HTTP
    HTTP --> GW
    GW --> AUTH
    GW --> SIM
    GW --> SCN
    GW --> ANA
    ANA --> REP
    SIM --> DB
    SCN --> DB
    ANA --> DB
    AUTH --> DB
```

Разделение ответственности: клиент отображает состояние и отправляет выбор игрока; сервер рассчитывает показатели (NFR-4).

## 7.4. Модель данных (черновик)

См. [diagrams/er.mmd](../diagrams/er.mmd).

```mermaid
erDiagram
    USER ||--o{ GROUP_MEMBER : состоит
    GROUP ||--o{ GROUP_MEMBER : содержит
    GROUP ||--o{ ASSIGNMENT : получает
    MODULE ||--o{ SCENARIO : включает
    SCENARIO ||--o{ STEP : содержит
    STEP ||--o{ OPTION : имеет
    USER ||--o{ GAME_SESSION : проходит
    SCENARIO ||--o{ GAME_SESSION : запускается
    GAME_SESSION ||--o{ DECISION : фиксирует
    OPTION ||--o{ DECISION : выбрана
    DECISION }o--|| ERROR_CATEGORY : классифицируется
    USER {
      int id
      string email
      string role
    }
    GAME_SESSION {
      int id
      int user_id
      int scenario_id
      jsonb state
      string status
    }
    DECISION {
      int id
      int session_id
      int option_id
      numeric balance_after
    }
```

Модель данных отражает требования FR-8, FR-9 и FR-12: состояние сессии хранится, решения фиксируются, ошибки классифицируются.

## 7.5. Соответствие диаграмм требованиям

| Диаграмма | Требования |
|---|---|
| Контекст | Все роли, NFR-3 (HTTPS) |
| Use case | FR-1 … FR-13 |
| Компоненты | FR-9, NFR-4, NFR-8 |
| ER | FR-8, FR-9, FR-12 |
