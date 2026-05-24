---
description: Apply when working with navigation, AppCoordinator, AppDestination, NavigationStack, or adding new screens
---

# Навигация (Coordinator Pattern)

## Концепция

`AppCoordinator` владеет `NavigationPath`. `AppCoordinatorView` содержит `NavigationStack` и собирает View по destination. `AppDestination` — чистый Hashable enum, не знает о View или DI.

## AppDestination

Только данные, необходимые для построения экрана:

```swift
enum AppDestination: Hashable {
    case photosetFeed
    case photosetDetail(PhotosetId)
    case photoViewer(photos: [Photo], startIndex: Int, photosetId: PhotosetId)
}
```

## AppCoordinator

```swift
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
}

extension AppCoordinator: Coordinator {
    func show(_ destination: AppDestination) {
        path.append(destination)
    }
}
```

`Coordinator` — протокол в Domain, ViewModel получает его через DI:

```swift
protocol Coordinator {
    func show(_ destination: AppDestination)
}
```

## AppCoordinatorView

Switch по destinations живёт здесь, не в `AppDestination`:

```swift
struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    let root: AppDestination
    let resolver: Resolver

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            view(for: root)
                .navigationDestination(for: AppDestination.self) { destination in
                    view(for: destination)
                }
        }
    }

    @ViewBuilder
    private func view(for destination: AppDestination) -> some View {
        switch destination {
        case .photosetFeed:
            resolver ~> PhotosetFeedView.self
        case .photosetDetail(let id):
            resolver ~> (PhotosetDetailView.self, argument: id)
        case .photoViewer(let photos, let index, let photosetId):
            resolver ~> (PhotoViewerView.self, arguments: (photos, index, photosetId))
        }
    }
}
```

## Как ViewModel инициирует переход

```swift
func didTap(photo: Photo) {
    guard let photos, let photoset = cachedPhotoset else { return }
    coordinator.show(
        .photoViewer(
            photos: photos,
            startIndex: photos.firstIndex(of: photo) ?? .zero,
            photosetId: photoset.id
        )
    )
}
```

View не вызывает навигацию напрямую — только через ViewModel.

## Добавление нового экрана

1. Добавить кейс в `AppDestination`
2. Добавить ветку в `AppCoordinatorView.view(for:)`
3. Создать папку в `Modules/` со своим `Assembly`, `View` и `ViewModel`
4. Зарегистрировать Assembly в `CullenApp`
