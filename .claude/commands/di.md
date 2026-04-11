# Dependency Injection (Swinject)

## DI-first принцип

Всё, что создаётся больше одного раза или имеет зависимости, регистрируется в DI. Это включает не только сервисы и Use Cases, но и **View и ViewModel**.

View регистрируется в Assembly как transient-фабрика — DI собирает весь модуль целиком включая ViewModel и все её зависимости. Transient означает новый инстанс при каждом `resolve()`, поэтому SwiftUI может пересоздавать View как обычно.

Если при добавлении нового типа возникает желание создать его через `SomeClass()` внутри другого класса — это сигнал что тип должен быть в DI.

## Организация

Каждый слой/модуль — отдельный `Assembly`. `Assembler` собирается один раз в `CullenApp`:

```swift
extension Cullen {
    static let resolver = Assembler([
        RepositoriesAssembly(),
        UseCasesAssembly(),
        PhotosetFeedAssembly(),
        PhotosetDetailAssembly(),
        PhotoViewerAssembly(),
        AppAssembly(),
        SystemAssembly(),
        MigrationsAssembly(),
    ]).resolver
}
```

## Регистрация

### autoregister — основной способ

Кастомный `autoregister` из `Utils/Autoregistration.swift` — parameter packs, тип выводится из инициализатора, `.self` не нужен:

```swift
// Конкретный тип без протокола
container.autoregister(PhotosetFeedViewModel.init)
    .inObjectScope(.weak)

// Если регистрируем под протоколом — .self нужен
container.autoregister(JsonPhotosRepository.self, initializer: JsonPhotosRepository.init)
    .inObjectScope(.container)

// Один инстанс под несколькими протоколами
container.autoregister(DecisionsUseCaseImpl.init)
    .inObjectScope(.container) // shared state + cache
    .implements(SaveDecisionUseCase.self)
    .implements(LoadDecisionsUseCase.self)
```

### Передача параметров — ParaMap

Для экранов с аргументами используем `ParaMap` из `Utils/ParaMap.swift`. Параметры кладутся в child container по типу:

```swift
// Call site (в AppCoordinatorView или другом View):
resolver ~> (PhotosetDetailView.self, with: photosetId)
resolver ~> (PhotoViewerView.self, with: photos, startIndex, photosetId)

// Assembly — без argument:, параметры приходят из child container автоматически:
container.autoregister(PhotosetDetailView.init)
container.autoregister(PhotosetDetailViewModel.init) // PhotosetId резолвится из ParaMap
    .inObjectScope(.weak)
```

**Важно**: не использовать примитивные типы (`Int`, `String`) как единственный параметр если в том же поддереве резолва есть другие зависимости того же типа — коллизия в child container.

### register с closure — только для сложных случаев

Когда `autoregister` не справляется (нестандартный init, условная логика):

```swift
container.register(ImageCache.self) { _ in .default }.inObjectScope(.weak)
container.register(Resolver.self) { $0 }.inObjectScope(.weak)
```

## Scopes

| Scope | Когда использовать |
|---|---|
| `.container` | Синглтоны — Repository, тяжёлые сервисы, `DecisionsUseCaseImpl`, `ImageCacheService` |
| `.weak` | ViewModel — живёт пока есть strong ref (обычно View) |
| по умолчанию (transient) | View, лёгкие объекты без состояния |

## SystemAssembly — что регистрируется

```swift
container.register(Resolver.self) { $0 }.inObjectScope(.weak)  // без этого баг с child containers
container.register(FileManager.self) { _ in .default }.inObjectScope(.weak)
container.register(UserDefaults.self) { _ in .standard }.inObjectScope(.weak)
container.register(ImageCache.self) { _ in .default }.inObjectScope(.weak)
```

## Utils/

- `Autoregistration.swift` — `container.autoregister(Type.init)` через parameter packs
- `ParaMap.swift` — child container для передачи параметров, операторы `~> (T.self, with: a)` / `~> (T.self, with: a, b)` / `~> (T.self, with: a, b, c)`
