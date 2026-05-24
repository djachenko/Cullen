---
description: Apply when implementing repositories, use cases, state enums, or any architectural patterns in the project
---

# Паттерны реализации

## Repository

```swift
// Протокол — в Domain, имя без суффикса
protocol PhotosetsRepository {
    func getPhotosetIds() async throws -> [PhotosetId]
    func getPhotoset(id: PhotosetId) async throws -> Photoset
    func getPhotosets() async throws -> [Photoset]
}

// Реализация — в Data, префикс описывает источник данных
final class JsonPhotosRepository: PhotosetsRepository { ... }
```

## JsonPhotosRepository — формат данных

Читает из бандла в два уровня:
- `index.json` — массив имён файлов: `["26.03.21.hindemith_rep.json", ...]`
- Каждый файл фотосета — словарь `"имя_файла.jpg" → "url"`: `{"DSC_0001.jpg": "https://..."}`

`PhotosetId` = `.string("26.03.21.hindemith_rep")` (имя файла без расширения).  
Название фотосета = имя файла.  
Дата парсится из начала имени файла (`yy.MM.dd`).  
Обложка = первый элемент после лексикографической сортировки.  
Фото сортируются лексикографически (TODO: обработка перехода через 0).

Lazy Task-кэш на уровне фотосета — файл грузится один раз при первом обращении:

```swift
func getPhotoset(id: PhotosetId) async throws -> Photoset {
    guard case .string(let filename) = id else {
        throw PhotosetsRepositoryError.notFound(id: id)
    }

    let task = photosetCache[id] ?? {
        let task = Task {
            let data = try self.jsonData(name: filename)
            let raw = try JSONDecoder().decode([String: URL].self, from: data)
            return Photoset(filename: filename, content: raw)
        }
        photosetCache[id] = task
        return task
    }()

    return try await task.value
}
```

`Photoset.init(filename:content:)` реализован как `private extension` на `Photoset` в файле репозитория.  
`PhotosetDTO` удалён — маппинг происходит напрямую.  
`JsonPhotosRepository` проставляет `source: .vk` для всех фотосетов.

## PhotosetSource

```swift
// Models/PhotosetSource.swift
enum PhotosetSource {
    case vk
}

extension PhotosetSource {
    var keyStrategy: String {
        switch self {
        case .vk: "index"
        }
    }
}
```

`source` влияет на стратегию экспорта решений и потенциально на UI (показывать ли имена файлов).

## Use Case

Один протокол — одна операция. Реализация — суффикс `Impl`:

```swift
protocol FetchPhotosUseCase {
    func execute(id: PhotosetId) async throws -> [Photo]
}

final class FetchPhotosUseCaseImpl: FetchPhotosUseCase {
    private let repository: PhotosetsRepository  // зависимость — всегда протокол

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }

    func execute(id: PhotosetId) async throws -> [Photo] { ... }
}
```

## PhotosetDetailState

Живёт в отдельном файле `Modules/PhotosetDetail/Models/PhotosetDetailState.swift`:

```swift
typealias PhotosetDetailContent = [PhotoGridCellViewModel]

enum PhotosetDetailState {
    case initial
    case loading
    case content(PhotosetDetailContent)
    case error(message: String)

    var isLoading: Bool { ... }
}
```

## DecisionsUseCaseImpl — actor

`DecisionsUseCaseImpl` реализован как `actor` для защиты от race condition при параллельных запросах:

```swift
actor DecisionsUseCaseImpl {
    private let repository: DecisionsRepository
    private var cache: [PhotosetId: [PhotoId: Decision]] = [:]
    // ...
}
```

Регистрируется с `.container` scope и через `.implements()` форвардит резолв обоих протоколов на тот же инстанс:

```swift
container.autoregister(DecisionsUseCaseImpl.self, initializer: DecisionsUseCaseImpl.init)
    .inObjectScope(.container)
    .implements(SaveDecisionUseCase.self)
    .implements(LoadDecisionsUseCase.self)
```

## ExportDecisionsUseCase

```swift
protocol ExportDecisionsUseCase {
    func execute(photosetId: PhotosetId, source: PhotosetSource) async throws -> Data
}
```

Формат экспортируемого JSON:
```json
{
  "key_strategy": "index",
  "decisions": {
    "good": [0, 3, 7],
    "bad": [1, 2, 5]
  }
}
```

- Ключи `good`/`bad` — маппинг из `.approved`/`.rejected` происходит внутри Use Case
- `.pending` фильтруется из экспорта
- `PhotosetsRepository` нужен для VK-стратегии (маппинг по индексу). TODO: разбить на отдельные стратегии

## DecisionsExport — Presentation-тип

`Transferable`-обёртка живёт в Presentation (не в Domain), потому что `Transferable` — протокол SwiftUI:

```swift
// Modules/PhotosetDetail/DecisionsExport.swift
struct DecisionsExport: Transferable, Identifiable {
    let filename: String
    let data: Data
    var id: String { filename }
}
```

Используется в `PhotosetDetailView` через `.sheet(item: $viewModel.export)` → `ShareLink`.  
После закрытия sheet `export` сбрасывается автоматически → следующий тап пересчитывает.

## JsonDecisionsRepository

Хранит решения в `Documents/Cullen/decisions/{photosetId}.json`. Формат — `[PhotoId: Decision]`.  
Директория создаётся в `init`. Fail-fast подход — если директория недоступна, `directory = nil`, любой вызов выбрасывает `Error.directoryUnavailable`.

## DTO → Domain

DTO живут в Data слое, конвертация через метод `toDomain()` или через `private extension` на Domain-типе в файле репозитория:

```swift
// private extension в JsonPhotosRepository.swift
private extension Photoset {
    init(filename: String, content: [String: URL]) {
        // маппинг из сырых данных в Domain entity
    }
}
```

## Ключевые решения по моделям

### decision убран из Photo

`decision` намеренно отсутствует в модели `Photo`. Решения живут отдельно в `DecisionsRepository`. Загрузка фото и решений — параллельная через `async let`, объединение — на уровне ViewModel при построении `[PhotoGridCellViewModel]`.

### PhotosetId

```swift
enum PhotosetId {
    case int(Int)
    case string(String)
    case uuid(UUID)
}
```

`stringValue` используется как имя JSON-файла для `JsonDecisionsRepository`.
