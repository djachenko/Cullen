# Cullen — Project Guide

## Цель проекта

Витринный проект для портфолио. Демонстрирует enterprise-подход на реальном приложении: Clean Architecture, DI, Coordinator, Repository, Use Cases. Код должен выглядеть как фрагмент большого production-проекта.

---

## Контекст приложения

Cullen — инструмент для отбора фотографий со съёмок.

**Типичный сценарий**: привезли со съёмки до 6000 фото → загрузили → отбираем.

**Текущий источник фото**: VK CDN (`sun9-*.userapi.com`) — временная заглушка.  
**Целевой источник**: Яндекс.Диск через WebDAV.

**Тестовые данные**: 295 фотосетов, 50 641 фото. Реальный рабочий объём — несколько активных сетов по ~6000 фото.

**Оффлайн-сценарий**: скачал фотосет дома на WiFi → отбираешь в электричке без связи. Нужен явный aggressive prefetch по запросу пользователя.

---

## Стек

| | |
|---|---|
| **Язык** | Swift 5.9+, async/await |
| **UI** | SwiftUI |
| **iOS** | 17.6+ |
| **DI** | Swinject + SwinjectAutoregistration |
| **Изображения** | Kingfisher |
| **Линтер** | SwiftLint |

---

## DI-соглашения

Поверх Swinject написаны два расширения в `Utils/`.

**Autoregistration** — `autoregister` без явного `.self`, тип выводится из инициализатора:
```swift
container.autoregister(PhotosetFeedViewModel.init)
    .inObjectScope(.weak)

// Если тип регистрируется под протоколом — оставляем явный .self:
container.autoregister(JsonPhotosRepository.self, initializer: JsonPhotosRepository.init)
    .inObjectScope(.container)

// Если конкретный тип + протоколы-алиасы — .implements:
container.autoregister(DecisionsUseCaseImpl.init)
    .implements(SaveDecisionUseCase.self)
    .implements(LoadDecisionsUseCase.self)
```

**ParaMap** — передача параметров вглубь иерархии резолва через child container. Вместо `argument:` в регистрации:
```swift
// Call site:
resolver ~> (PhotosetDetailView.self, with: photosetId)
resolver ~> (PhotoViewerView.self, with: photos, startIndex, photosetId)

// Assembly — без argument:, параметры приходят из ParaMap:
container.autoregister(PhotosetDetailViewModel.init) // PhotosetId резолвится из child
```

Параметры кладутся в child container по типу — не использовать примитивные типы (`Int`, `String`) как единственный параметр экрана, если в том же поддереве резолва есть другие зависимости того же типа.

---

## Структура проекта

```
Cullen/
├── Application/
│   ├── CullenApp.swift              # Entry point, Assembler
│   ├── AppAssembly.swift            # DI регистрации для App-слоя
│   ├── AppCoordinator.swift         # NavigationPath + навигационные actions
│   ├── AppCoordinatorView.swift     # NavigationStack + switch по destinations
│   ├── AppDestination.swift         # Enum всех экранов (Hashable)
│   └── KingfisherConfiguration.swift
│
├── Models/                          # Domain entities (чистые, без UI/Data зависимостей)
│   ├── Photo.swift
│   ├── Photoset.swift               # + поле source: PhotosetSource
│   ├── PhotosetSource.swift         # enum PhotosetSource { case vk }
│   ├── PhotosetInfo.swift
│   ├── PhotosetStatistics.swift
│   ├── Decision.swift
│   └── SyncStatus.swift
│
├── Repositories/                    # Data layer
│   ├── PhotosetsRepository.swift    # Протокол
│   ├── DecisionsRepository.swift    # Протокол
│   ├── JsonPhotosRepository.swift   # Читает index.json + отдельные файлы фотосетов
│   ├── JsonDecisionsRepository.swift # JSON-файлы в Documents/Cullen/decisions/
│   └── RepositoriesAssembly.swift
│
├── UseCases/                        # Domain layer — бизнес-логика
│   ├── FetchPhotosetInfoUseCase.swift
│   ├── FetchPhotosUseCase.swift
│   ├── FetchPhotosetUseCase.swift
│   ├── FetchPhotosetsUseCase.swift
│   ├── GetPhotoSetStatisticsUseCase.swift
│   ├── DecisionsUseCase.swift       # SaveDecisionUseCase + LoadDecisionsUseCase
│   ├── ExportDecisionsUseCase.swift # execute(photosetId:source:) -> Data
│   ├── SwipePhotoUseCase.swift
│   └── UseCasesAssembly.swift
│
├── Modules/                         # Presentation layer
│   ├── PhotosetFeed/
│   ├── PhotosetDetail/
│   └── PhotoViewer/
│
├── Utils/
│   ├── Autoregistration.swift       # autoregister(Type.init) без .self, parameter packs
│   └── ParaMap.swift                # ParaMap + ~> оператор с with: для child container DI
│
├── Extensions/
└── Assets.xcassets
```

**Правило:** новый экран = новая папка в `Modules/` со своим `Assembly`, `View` и `ViewModel`.

---

## Архитектура

```
Presentation → Domain ← Data
```

- **Domain** (`Models/`, `UseCases/`, протоколы репозиториев) — не зависит ни от чего, кроме Foundation
- **Data** (`Repositories/`) — реализует протоколы из Domain
- **Presentation** (`Modules/`) — зависит от Domain, не знает о Data

Нарушение dependency rule — блокер для merge.

**ViewModel** — тонкий, только UI state. Не содержит бизнес-логики — делегирует в Use Cases.  
**Use Case** — одна операция, одна ответственность, метод `execute()`.  
**Repository** — протокол в Domain, реализация в Data.

---

## Скиллы (детальные гайды)

### Архитектура
- `/di` — Swinject DI: scopes, autoregister, ParaMap, child container resolution
- `/navigation` — Coordinator pattern, AppDestination, добавление нового экрана
- `/patterns` — Repository, UseCase, Decisions, Export — детали реализации
- `/migration` — MigrationService: паттерн, существующие миграции, как добавить новую
- `/observable` — план миграции на @Observable

### Стиль & Качество
- `/style` — Naming conventions, code style, pre-commit checklist
- `/issues` — Known bugs и структурные ограничения

### Фичи & Эпики
- `/backlog` — текущий фокус, что в работе, что следующее
- `/connectors` — архитектура коннекторов и источников данных, планируемые источники
- `/prefetch` — PrefetchManager, оффлайн-кэш, стратегии разрешения

### Инфраструктура
- `/cli` — Python CLI: cullen.py, формат данных, sources.py
- `/spm` — план SPM-пакетов (CullenUI, SwiftFoundationExtensions, CullenDesignSystem)
- `/distribution` — AltStore, индикатор срока подписи
