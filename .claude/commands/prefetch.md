# Оффлайн & Prefetch

## Планируемая архитектура

### ImageCacheService

```swift
enum PrefetchEvent {
    case progress(completed: Int, total: Int)
    case finished
}

typealias CacheKey = URL

protocol ImageCacheService {
    func startPrefetch(urls: [CacheKey]) -> AsyncStream<PrefetchEvent>
    func isCached(url: CacheKey) -> Bool
}
```

Реализация `KingfisherImageCacheService` — через `ImagePrefetcher` из Kingfisher.  
Регистрируется в `RepositoriesAssembly` с `.container` scope.  
`ImageCache.self` регистрируется в `SystemAssembly` (`.default`).

### CacheUseCase

```swift
protocol CacheUseCase {
    func prefetch(photoset: PhotosetId) async throws -> AsyncStream<PrefetchEvent>
    func cacheRatio(photoset: PhotosetId) async throws -> Double
}
```

`CacheUseCaseImpl` берёт URL фото из `PhotosetsRepository`, делегирует в `ImageCacheService`. Регистрируется в `UseCasesAssembly`.

### PhotosetDetailPrefetchState

```swift
enum PhotosetDetailPrefetchState: Equatable {
    case notCached
    case partial(ratio: Double)
    case prefetching(progress: Double)
    case full
}
```

### UI в PhotosetDetail

`prefetchButton` в toolbar — toggle через `didTapPrefetchButton()`:
- `.notCached` / `.partial` → startPrefetch
- `.prefetching` → cancelPrefetch
- `.full` → clearCache

`onDisappear` → `cancelPrefetch()`.

---

## Разрешение для оффлайн кэша

Открытый вопрос: **1280px** (~300KB/фото, ~1.8GB на 6000 фото) vs **2560px** (~1MB/фото, ~6GB на 6000 фото).  
Компромисс: **1280px для оффлайна**, 2560px по требованию при наличии сети.

---

## На карточке фотосета (не реализовано)

- Кнопка «Скачать» / «Отменить» на `PhotosetCardView`
- `PhotosetCardViewModel` получает `PrefetchStatus` из `CacheUseCase`
- Прогресс — `SegmentedProgressBarView` под прогрессом отбора

## Управление кэшем (не реализовано)

- Показать размер кэша (диск + память) и лимит
- Очистка по фотосету или всего
- Настройка лимита (слайдер или пресеты: 1GB / 2GB / 4GB)
- Стратегии TTL по решению: approved/rejected вытесняются первыми, pending держим дольше
