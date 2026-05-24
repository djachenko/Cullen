---
description: Apply when migrating ObservableObject/Published to @Observable macro or working with SwiftUI state
---

# Миграция на @Observable

## Подготовка

iOS 17.6 — выставлен ✅

**Важно перед массовой миграцией**: проверить `.weak` scope с `@Observable`. `WeakStorage` в Swinject работает через `AnyObject`, `@Observable`-классы его поддерживают — написать минимальный тест-кейс.

---

## Паттерн миграции

| До | После |
|---|---|
| `@Published var x` | просто `var x` |
| `@StateObject var vm` | `@State var vm` |
| `@ObservedObject var vm` | `@Bindable var vm` (если нужен binding) или просто передаём |
| `ObservableObject` | `@Observable` |

---

## ViewModels

### PhotosetFeedViewModel
```swift
// До
final class PhotosetFeedViewModel: ObservableObject {
    @Published var state: PhotosetFeedState = .initial
}
// После
@Observable
final class PhotosetFeedViewModel {
    var state: PhotosetFeedState = .initial
}
```
В View: `@StateObject` → `@State`.

### PhotosetDetailViewModel
Аналогично. `@StateObject` → `@State`.

### PhotoViewerViewModel
`@ObservedObject` → `@Bindable` (если нужен Binding) или без обёртки.

### PhotosetCardViewModel
`@StateObject` → `@State`.

---

## AppCoordinator

```swift
// До
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
}

// После
@Observable
final class AppCoordinator {
    var path = NavigationPath()
}
```

В `AppCoordinatorView`:
- Убрать `@ObservedObject`
- Получать binding через `@Bindable`: `@Bindable var coordinator: AppCoordinator`
- `NavigationStack(path: $coordinator.path)` — проверить что работает корректно

---

## Combine-подписки

Проверить все `sink`/`assign`. Заменить на нативные механизмы `@Observable` где возможно (`.onChange`, computed properties).
