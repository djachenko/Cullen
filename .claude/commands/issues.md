# Known Issues & Limitations

## Активные баги

### PhotosetDetail — сброс скролла при возврате из PhotoViewer

`NavigationStack` пересоздаёт View при pop, `@StateObject` ViewModel умирает вместе с ней. Скролл сбрасывается в начало. Решение — `.inObjectScope(.weak)` в Swinject + `@StateObject` с кастомным `init(viewModel:)` (уже применено для `PhotosetDetailViewModel`), но проблема остаётся из-за пересоздания всей View.

### PhotosetDetail — gridWidth не обновляется при смене ориентации

По той же причине: View пересоздаётся, `onGeometryChange` не срабатывает сразу после pop. Остаётся landscape-ширина в portrait.

## Структурные ограничения

### NavigationStack и ViewModel lifecycle

`NavigationStack` не сохраняет View и ViewModel между переходами — они пересоздаются при каждом `navigationDestination`. Решение: `.inObjectScope(.weak)` в Swinject + `@StateObject` с `init(viewModel:)`.

### ScrollView и NavigationBar large title

ScrollView всегда должен присутствовать в иерархии. Условный показ/скрытие ScrollView десинхронизирует large title. Фикс: ScrollView — всегда внешний элемент, loading/content/error — внутри него.

### LazyVGrid с .flexible() и flickering large title

`.flexible()` колонки вызывают флики large title. Решение: `.fixed(columnWidth)` + `onGeometryChange` для вычисления ширины.

### VK CDN троттлинг

Network timeout errors в логах симулятора при одновременных запросах — ожидаемое поведение. Митигировано через `httpMaximumConnectionsPerHost = 4` и `downloadTimeout = .minutes(2)`. Реальное тестирование — только на устройстве.
