---
description: Apply when working on data source connectors, DataSourceConnector protocol, or AggregatedPhotosetsRepository
---

# Коннекторы & Источники данных

## Архитектура

### Протоколы (Domain)

```swift
protocol DataSourceConnector {
    var id: ConnectorId { get }
    var type: ConnectorType { get }
    var authStatus: AuthStatus { get }
    func connect() async throws
    func disconnect() async throws
    func fetchPhotosets() async throws -> [Photoset]
}

protocol DataSource {
    var id: DataSourceId { get }
    var connectorId: ConnectorId { get }
    var name: String { get }
    var isEnabled: Bool { get }
    func fetchPhotosets() async throws -> [Photoset]
}
```

### Репозитории

- `ConnectorsRepository` — хранит список созданных коннекторов в persistence
- `DataSourcesRepository` — хранит список настроенных источников с настройками

### Уникальность ID при нескольких источниках

Фотосеты из разных провайдеров окажутся в одном списке. ID должны быть глобально уникальны — VK-альбом `123` и Яндекс.Диск-папка `123` не должны коллидировать в `DecisionsService` и `LastOpenedRepository`. Конкретный механизм (namespace-префикс, enum с кейсом на источник) — решить при реализации первого сетевого коннектора. До тогда — не менять преждевременно. (ADR-02 в decisions)

### AggregatedPhotosetsRepository

Параллельно вызывает `fetchPhotosets()` у всех активных `DataSource`, мержит `[Photoset]`:
- При ошибке одного источника — не падает целиком, показывает частичные результаты + индикатор ошибки у конкретного источника
- Pull-to-refresh и кнопка «Обновить» инвалидируют кэш и перезапрашивают все источники
- Подключить к `FetchPhotosetsUseCase` и `FetchPhotosetUseCase` вместо `JsonPhotosRepository`

### DI

Все типы коннекторов регистрируются через именованные регистрации или фабрику.

---

## Экран управления коннекторами

- `ConnectorsView` + `ConnectorsViewModel` → `ConnectorsAssembly` → новый кейс в `AppDestination`
- Список подключённых коннекторов: тип (иконка), название/аккаунт, статус
- Кнопка «Добавить» → sheet с выбором типа коннектора
- Удаление с подтверждением — каскадно удаляет связанные источники данных

## Экран настройки источника

- `DataSourceSetupView` + `DataSourceSetupViewModel`, параметризован коннектором
- Браузер папок/альбомов коннектора
- Несколько источников с одного коннектора (разные папки на одном Яндекс.Диске)
- Тогл включить/выключить источник без удаления

---

## Планируемые коннекторы

### Яндекс.Диск (WebDAV) — приоритет
- OAuth через Яндекс.ID → токен в Keychain
- WebDAV клиент: оценить FilesProvider или написать минимальный свой
- Маппинг: папка верхнего уровня = фотосет, файлы внутри = фото
- `SyncDecisionsUseCase` — перемещает файлы в `approved/` / `rejected/` на диске
- `SyncStatus` — реальный статус синхронизации
- Фоновая синхронизация через Background Tasks

### VK
- OAuth VK → токен в Keychain
- `photos.getAlbums` — список альбомов
- `photos.get` — фото из альбома, брать максимальный размер из `as=` параметра URL
- Матчинг по порядку при экспорте (имена файлов недоступны)

### Галерея iOS (Photos framework)
- Доступ через Photos framework
- Стратегия: физически удалять из галереи или только писать в JSON — на выбор
- Раз есть локальный доступ — читать напрямую, не через Kingfisher кэш

### SMB (локальная сеть)
- Библиотека AMSMB2
- UI: хост, share name, логин, пароль → Keychain
- Сценарий: отбор дома с компа через роутер

### FTP
- UI: хост, порт, логин, пароль, путь → Keychain

### wfolio
- Исследовать: HTML-парсинг или JSON endpoints (XHR, GraphQL)
- Только чтение — обратная запись недоступна

---

## Текущее состояние (до эпика)

`JsonPhotosRepository` — временная реализация, читает из бандла. При старте эпика:
- Выделить в `JsonBundleConnector` реализующий `DataSourceConnector`
- Подключить через `AggregatedPhotosetsRepository`
