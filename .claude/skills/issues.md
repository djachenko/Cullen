---
description: Apply when encountering known bugs or structural limitations — NavigationStack lifecycle, ScrollView, VK CDN
---

# Known Issues & Limitations

## Активные баги

### ~~PhotosetDetail — сброс скролла при возврате из PhotoViewer~~

Закрыто. `@StateObject(wrappedValue:)` в `init(viewModel:)` + `.inObjectScope(.weak)` держат ViewModel живой пока View в стеке. `NavigationStack` View не пересоздаёт.

### ~~PhotosetDetail — gridWidth не обновляется при смене ориентации~~

Закрыто. `.onAppear` + `.onChange(of: geometry.size.width)` — при возврате из PhotoViewer `onAppear` обновит ширину.

## Структурные ограничения

### NavigationStack и ViewModel lifecycle

`NavigationStack` не сохраняет View и ViewModel между переходами — они пересоздаются при каждом `navigationDestination`. Решение: `.inObjectScope(.weak)` в Swinject + `@StateObject` с `init(viewModel:)`.

### ScrollView и NavigationBar large title

ScrollView всегда должен присутствовать в иерархии. Условный показ/скрытие ScrollView десинхронизирует large title. Фикс: ScrollView — всегда внешний элемент, loading/content/error — внутри него.

### LazyVGrid с .flexible() и flickering large title

`.flexible()` колонки вызывают флики large title. Решение: `.fixed(columnWidth)` + `onGeometryChange` для вычисления ширины.

### ~~VK CDN троттлинг~~

Закрыто. `httpMaximumConnectionsPerHost = 4` + `downloadTimeout = .minutes(2)` решили проблему.

---

## Баги из code review (май 2026)

### ~~BUG-01~~: `ViewerSettingsRepository` — зарегистрирован в `PhotoViewerAssembly`. Не баг.

### ~~BUG-02~~: Лимит дискового кеша Kingfisher — 16 ГБ, намеренно. Не баг.

### BUG-03: `JsonDecisionsRepository` — мёртвый `Error.directoryUnavailable`

`directory` уже non-optional — основной баг починен. Остался мёртвый `enum Error { case directoryUnavailable }` — удалить.

```swift
private let directory: URL

init(fileManager: FileManager) {
    self.fileManager = fileManager
    let base = fileManager
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(component: Constants.directoryName)
        .appending(component: Constants.subdirectory)
    try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
    self.directory = base
}
```

### BUG-04: `JsonPhotosRepository.getPhotoset` — кеш всегда перезаписывается

```swift
let task = photosetCache[id] ?? Task { ... }
photosetCache[id] = task  // перезаписывает даже если task был в кеше
```
Исправить:
```swift
if let cached = photosetCache[id] {
    return try await cached.value
}
let task = Task { ... }
photosetCache[id] = task
return try await task.value
```

### BUG-05: `PhotoViewerViewModel.applyDecision` — GCD внутри `@MainActor`

`DispatchQueue.main.asyncAfter` в классе помеченном `@MainActor`. Заменить на:
```swift
Task { [weak self] in
    try? await Task.sleep(for: .milliseconds(150))
    withAnimation(.easeInOut(duration: 0.25)) {
        self?.currentIndex += 1
    }
}
```

### BUG-06: `DateFormatter` без `locale`

В `JsonPhotosRepository` `DateFormatter` создаётся без `locale`. На нестандартных локалях поведение непредсказуемо.

```swift
private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yy.MM.dd"
    return f
}()
```

### BUG-07: `Decodable.fromJson` бросает `URLError`

`throw URLError(.fileDoesNotExist)` при отсутствии ресурса в бандле — семантически неверно. Заменить на:

```swift
enum BundleError: Error {
    case resourceNotFound(name: String, extension: String)
}
// throw BundleError.resourceNotFound(name: name, extension: "json")
```

### BUG-08: `KingfisherImageCacheService` — отсутствие изоляции

Класс не изолирован, `prefetcher` — mutable state. Фактически безопасен только из `@MainActor`-контекста. Добавить `@MainActor` на класс и протокол. Сначала перепроверить на наличие реальных крэшей при prefetch.

### BUG-09: `PhotosetFeedViewModel` — двойной запуск `loadPhotosets` на старте

`loadPhotosets()` вызывается дважды: из `.task` во View и из Combine-подписки через 300ms (`CombineLatest3` эмитит при подписке). Исправить:

```swift
Publishers.CombineLatest3($searchText, $selectedSortOption, $sortDirection)
    .dropFirst()
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { ... }
```

### BUG-10: `searchText` в Combine без реализации поиска

`$searchText` входит в `CombineLatest3` но фильтрация не применяется. Убрать из Combine. Поиск реализовать отдельно (T-01 в бэклоге).

### BUG-11: Синхронизация decisions между PhotosetDetail и PhotoViewer

После свайпа во PhotoViewer при возврате бейджи в PhotosetDetail не обновляются — Detail хранит decisions с момента открытия. Сначала перепроверить что баг воспроизводится. Стратегии: reload в `onAppear`, или `@Published decisions` в `DecisionsService`. (T-02 в бэклоге)
