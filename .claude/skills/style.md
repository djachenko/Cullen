---
description: Apply when writing or reviewing Swift code — naming conventions, file structure, extensions, formatting, pre-commit checklist
---

# Naming Conventions, Code Style & Pre-commit

## Naming — Типы

```swift
// Use Case протокол — глагол + объект + UseCase
FetchPhotosetInfoUseCase
GetPhotosetStatisticsUseCase
ExportDecisionsUseCase

// Use Case реализация — суффикс Impl
FetchPhotosetInfoUseCaseImpl
ExportDecisionsUseCaseImpl

// Repository протокол — существительное + Repository
PhotosetsRepository
DecisionsRepository

// Repository реализация — источник данных + Repository
JsonPhotosRepository
JsonDecisionsRepository

// ViewModel — экран/компонент + ViewModel
PhotosetFeedViewModel
PhotosetCardViewModel

// View — экран/компонент + View
PhotosetFeedView
PhotosetCardView

// Assembly — модуль + Assembly
PhotosetFeedAssembly
RepositoriesAssembly
```

## Naming — Методы

```swift
// Use Cases — execute() с именованными аргументами при необходимости
func execute() async throws -> PhotosetStatistics
func execute(id: PhotosetId) async throws -> [Photo]
func execute(photosetId:source:) async throws -> Data

// ViewModel — описательный глагол
func loadPhotosets() async
func exportDecisions()
func resetDecision()
```

## Naming — Файлы

Один публичный тип = один файл. Имя файла = имя типа:
- `DecisionsUseCase.swift` содержит протоколы `SaveDecisionUseCase`, `LoadDecisionsUseCase` и класс `DecisionsUseCaseImpl`
- `PhotosetDetailViewModel.swift` содержит `PhotosetDetailViewModel`, `PhotosetDetailState`, `PhotosetDetailContent`

## Code Style — Файловая структура

Вместо MARK-секций используем `extension` для логической группировки. Основное тело типа — только свойства и `init`. Методы — в extensions:

```swift
final class PhotosetDetailViewModel: ObservableObject {
    // Только хранимые свойства и init
    @Published var state: PhotosetDetailState = .initial
    @Published var export: DecisionsExport?

    private let coordinator: Coordinator
    private let exportDecisionsUseCase: ExportDecisionsUseCase
    // ...

    init(...) { ... }
}

extension PhotosetDetailViewModel {
    func loadPhotos() async { ... }
    func exportDecisions() { ... }
}

private extension PhotosetDetailViewModel {
    func didTap(photo: Photo) { ... }
}
```

Приватная логика — по максимуму в `private extension`. Хранимые свойства остаются в основном теле.

Для View — отдельные extensions на каждую смысловую группу subview.

## Code Style — Форматирование

- Никаких однострочных `guard`, `if/else`, closures — всегда многострочно со скобками
- Implicit return везде где возможно (computed properties, single-expression functions)
- `final` у всех классов по умолчанию
- Trailing comma в multiline — да, упрощает diff
- Force unwrap (`!`) — только с комментарием почему безопасно
- Magic numbers/strings — в `private enum Constants` или `private enum Layout`

```swift
// ✅
private enum Layout {
    static let maxZoomScale: CGFloat = 5
    static let doubleTapZoomScale: CGFloat = 3
}

// ❌
scrollView.maximumZoomScale = 5
```

## Pre-commit Checklist

- [ ] SwiftLint — 0 violations
- [ ] Новые зависимости инжектируются через `init`, не создаются внутри
- [ ] Новый тип с зависимостями зарегистрирован в Assembly
- [ ] Domain не импортирует UIKit/SwiftUI
- [ ] Use Case содержит логику — ViewModel только меняет state
- [ ] Новый экран зарегистрирован в Assembly и добавлен в `AppDestination`
- [ ] `Transferable`-типы и SwiftUI-зависимые обёртки — только в Presentation
- [ ] Маппинг между Data и Domain — в Use Case или `private extension` на Domain-типе
