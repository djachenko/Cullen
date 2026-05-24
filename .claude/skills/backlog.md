---
description: Apply when discussing what to work on next, prioritizing tasks, or planning the next feature
---

# Backlog — текущий фокус

## В работе / ближайшие задачи

_(пусто — заполнить при старте следующего эпика)_

---

## Отложенные задачи

### T-01: Реализовать поиск в PhotosetFeed

`searchText` сейчас входит в `CombineLatest3` но фильтрация не применяется. Убрать из Combine, реализовать отдельной подпиской с debounce.

### T-02: Синхронизация decisions между PhotosetDetail и PhotoViewer

После свайпа во PhotoViewer при возврате в PhotosetDetail бейджи не обновляются — Detail хранит decisions с момента открытия. Стратегии: reload в `onAppear` / `.task`, или `@Published decisions` в `DecisionsService` с подпиской из обоих VM. Сначала перепроверить что баг воспроизводится.

### T-03: Collapsible header со статистикой в PhotosetDetail

Писать с нуля. `__trash/` не использовать — устаревший код.

### T-04: Мигрировать `GetPhotosetStatisticsUseCase` с `getPhotosets()`

Переписать на `getPhotosetIds()` + поштучный `getPhotoset`. Убрать deprecated метод из репозитория после миграции.

### T-05: `CullenImage` → `struct View`

Только при расширении функциональности: retry, контекстные placeholder'ы. До тогда — оставить как функцию. См. ADR-09 в decisions.

### T-06: Несоответствие дефолтного `sortDirection` в FeedViewModel

`sortDirection` инициализируется через `lastOpened.defaultDirection`, но `selectedSortOption` — `.recent`. Проверить поведение на первом запуске (чистая установка без UserDefaults).

### T-07: Глобальная уникальность `PhotosetId` при нескольких коннекторах

Решить при реализации первого сетевого коннектора. Варианты: namespace-префикс в строке, enum с кейсом на источник. Без нескольких реальных источников — преждевременно. См. ADR-02 в decisions.

### T-08: Пересмотр `PhotoId` при сетевых коннекторах

VK API использует int для photo ID. Одновременно с T-07. См. ADR-03 в decisions.

---

## Технический долг

### Переименования (не менялись из-за масштаба)

- `DecisionsUseCaseImpl` → `DecisionsService` (см. ADR-05)
- `AppCoordinator` → `AppRouter`, протокол `Coordinator` → `Router` (см. ADR-06)

### Удалить `__trash/`

Папка `app/Cullen/__trash/` — старый код коллапсируемого хедера. Удалить. Git history сохранит: `git log --all --full-history -- '**/BottomBar.swift'`.

### Закомментированный код к удалению

- `SwipePhotoUseCase.swift` — весь файл, старая концепция с sync-сервисом
- `ViewerMode.buttons` — закомментированный третий режим вьюера
- `onSingleTap` в `PhotoViewerView` — незаконченная фича
- `prefetchAhead` в `PhotosetDetailView` — незаконченная фича
- `// Business Logic: Calculate statistics` в `GetPhotosetStatisticsUseCase`
- `.fill(Color(.systemBackground))` в `PhotosetCard`

### `SwipeDirection` — цвет, иконка, лейбл

`// TODO: Should color, icon and label be here???` — решить где держать визуальное представление направления свайпа.
