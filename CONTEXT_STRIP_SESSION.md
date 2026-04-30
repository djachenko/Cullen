# Cullen — контекст сессии (Strip режим)

Дата: апрель 2026. Ворктри: `strip-viewer`.

---

## Что было сделано в этой сессии

### 1. Патч из предыдущей сессии (применён)

Добавлены режимы просмотра (`ViewerMode`) и персистентность настроек.

**Новые файлы:**
- `Models/ViewerSettings.swift` — `ViewerMode: String, CaseIterable, Codable` (`.compass`, `.strip`, `.buttons`) + `ViewerSettings: Codable`
- `Repositories/ViewerSettingsRepository.swift` — протокол `load(for:) / save(_:for:)`
- `Repositories/UserDefaultsViewerSettingsRepository.swift` — реализация через `@Preference` wrapper

**Изменены:**
- `PhotoViewerViewModel` — добавлены `@Published var settings`, `let photos` стал `internal`, методы `applyDecision(_:)` и `cycleViewerMode()`
- `PhotoViewerView` — `@ViewBuilder var modeView` роутит на нужную вью по режиму; кнопка смены режима в toolbar
- `PhotoViewerAssembly` — регистрация `UserDefaultsViewerSettingsRepository`

**`cycleViewerMode`** в ViewModel намеренно использует `modes.count - 1` вместо `modes.count` — чтобы пропускать `.buttons` (не реализован).

### 2. @Preference property wrapper

`Utils/Preference.swift` — property wrapper для UserDefaults по образцу DromAuto. Поддерживает:
- Примитивы (`Bool`, `Int`, `Double`, `String`, `Data`)
- `RawRepresentable` с `String` и `Int` rawValue
- Опционалы

`UserDefaultsViewerSettingsRepository` использует его для хранения `ViewerMode` как raw string. Ключ: `"viewerMode_\(photosetId)"`.

### 3. VerticalStripView (старая версия, не в production)

`Modules/PhotoViewer/VerticalStripView.swift` — UIKit-реализация с `UIScrollView + isPagingEnabled`. Fullscreen-ячейки. В `PhotoViewerView` закомментирована, не используется.

### 4. PrototypeStrip — две версии (папка `PrototypeStrip/`)

Codex написал два прототипа пока шло обсуждение архитектуры.

#### `PrototypeVerticalStripView`
- SwiftUI `ScrollView + LazyVStack`, aspect-ratio карточки
- `.scrollTargetBehavior(.viewAligned)` + `.scrollPosition(id:anchor:.center)` для snap
- `scrollDisabled(zoomScale > 1)`
- `PrototypeStripZoomableImageView` (UIViewRepresentable) внутри карточки — UIScrollView zoom, double tap, aspect ratio callback
- **Нет swipe-to-decide** — только decision badge
- Зум ограничен границами карточки

#### `PrototypeOverlayStripView`
- Тот же список, но активная карточка рендерится в ZStack overlay поверх
- Плейсхолдер в списке скрывается когда overlay активен
- `PrototypeOverlayInteractiveImageView` — "плавающий" зум: при пинче извлекает image во window-уровень UIImageView
- Есть swipe-to-decide через горизонтальный pan
- Floating zoom возвращается назад при отпускании (snap back) — это не то что нужно

Оба прототипа живут в `PrototypeStrip/`, не подключены к production flow.

---

## StripV3 — текущая реализация (активна)

**Папка:** `Modules/PhotoViewer/StripV3/`  
**Подключена в** `PhotoViewerView.swift` в `.strip` кейсе.

### Архитектура

```
StripV3View (SwiftUI)
  ├── SwiftUI ScrollView + LazyVStack  ← лента, snap, scroll-disable
  │     └── StripV3CardView × N
  │           └── StripV3ZoomableCardView (UIViewRepresentable)
  │                 └── StripV3CardContentView (UIView)
  │                       ├── StripV3ScrollView (UIScrollView, zoom)
  │                       ├── approveOverlay / rejectOverlay
  │                       └── imageView (UIImageView)
  └── StripV3FullScreenGestureRelay (UIViewRepresentable, прозрачный, full-screen)
        └── StripV3RelayView (UIView, hitTest override)
```

**Общий объект:** `StripV3ZoomCoordinator: ObservableObject` (@StateObject в StripV3View).

### Стейт-машина (3 состояния)

| Состояние | Условие | Лента | Swipe-to-decide | Зум/Пан |
|---|---|---|---|---|
| **Scrolling** | `isScrolling = true` | ON | OFF | OFF |
| **Idle** | `isScrolling = false`, `zoomScale == 1` | ON | ON | Pinch → Zoomed |
| **Zoomed** | `zoomScale > 1` | OFF (`.scrollDisabled`) | OFF | ON |

### Файлы

#### `StripV3ZoomCoordinator.swift`
- `@Published var zoomScale: CGFloat`
- `weak var activeScrollView: UIScrollView?`
- `registerActive(_ scrollView:)` — регистрирует активную карточку, сбрасывает предыдущую
- `beginPinch(at:relayView:)` / `updatePinch(gestureIncrement:)` — pinch-to-point математика
- `applyPan(dx:dy:)` — пан в зазумленном состоянии
- `resetZoom(animated:)` — сброс зума
- `notifyZoomChange(_ scale:)` — вызывается UIScrollView delegate карточки

#### `StripV3ZoomableCardView.swift`
UIViewRepresentable карточки. Внутри `Coordinator`:
- `StripV3ScrollView` (UIScrollView subclass с `onLayout` callback) — нативный zoom-to-point, persistent zoom
- `clipsToBounds = false` на UIScrollView → зазумленное фото визуально вылезает за границы
- `decisionPan` — горизонтальный pan, gate: `zoomScale == 1 && abs(vx) > abs(vy)`
- `doubleTap` — zoom in/out
- При `config.isActive = true` → `zoomCoordinator.registerActive(scrollView)`
- `StripV3DecisionOverlayView` (approve/reject, зелёный/красный)

Config: `StripV3ZoomableCardViewConfig` (struct, callbacks: `onZoomScaleChange`, `onAspectRatioChange`, `onDecision`)

#### `StripV3FullScreenGestureRelay.swift`
- Прозрачный полноэкранный UIViewRepresentable
- `allowsHitTesting(zoomCoordinator.zoomScale > 1)` — активен только при зуме
- `StripV3RelayView.hitTest` — **ключевое**: если касание попадает в активную карточку (по координатам UIScrollView), возвращает `nil` → касание проваливается к UIScrollView под ним. За пределами карточки — relay обрабатывает сам.
- Gestures: `UIPinchGestureRecognizer` → координатор, `UIPanGestureRecognizer` → координатор, double tap → `resetZoom`
- `shouldRecognizeSimultaneously` → `true` (pinch + pan одновременно)

#### `StripV3View.swift`
- `@StateObject private var zoomCoordinator`
- Лента: `ScrollView(.vertical) + LazyVStack + .scrollTargetLayout() + .scrollTargetBehavior(.viewAligned) + .scrollPosition(id: $scrollTarget, anchor: .center)`
- Edge insets: `(viewportHeight - cardWidth / defaultAspectRatio) / 2`  (дефолтное 3:2, обновляется при загрузке реального aspect ratio)
- Frame tracking через `PreferenceKey` → `scheduleFrameUpdate` → `syncActivePhoto` → `markScrolling` (debounce 0.18s)
- `StripV3CardView` — SwiftUI wrapper: `clipShape` только когда `!isZoomed`, `zIndex(1)` когда `isZoomed`
- `onChange(viewModel.currentIndex)` → snap к новому фото (после `applyDecision`)

### Как работает зум за пределами карточки

```
Пальцы ЗА карточкой, zoom > 1:
  touch → StripV3RelayView.hitTest → returns self (не nil)
  → UIPinchGestureRecognizer на relay
  → Coordinator.handlePinch
  → zoomCoordinator.beginPinch(at:relayView:)
    → location конвертируется в координаты UIScrollView
    → anchor в content coordinates фиксируется
  → updatePinch(gestureIncrement:)
    → scrollView.setZoomScale(newScale)
    → scrollView.contentOffset = anchorContent * newScale - anchorInScrollView
    → визуально изображение зумится в точку пинча

Пальцы В карточке, zoom > 1:
  touch → StripV3RelayView.hitTest → returns nil (пропускает)
  → UIScrollView получает нативный pinch/pan
  → UIScrollView сам обрабатывает (нативный zoom-to-point)
```

---

## Открытые вопросы и TODO

### Требует проверки

1. **Aspect ratio и edge insets** — используется дефолтный 3:2 для edge inset. Нестандартные соотношения могут чуть криво центрироваться. Не блокер для MVP.

2. **`isScrolling` detection** — через `onScrollPhaseChange`. Иногда триггерится лишний раз при relayout. Не блокер.

### Не реализовано / открытые баги

- **Режим `.buttons`** — в `cycleViewerMode` пропускается. В `modeView` фолбэчится на compass.
- **ResetDecisionUseCase** — пишет `.pending` вместо удаления ключа.
- **Спиннеры загрузки** — нет индикации нигде.

---

## Структура файлов (актуальная)

```
app/Cullen/
├── Models/
│   └── ViewerSettings.swift
├── Repositories/
│   ├── ViewerSettingsRepository.swift
│   └── UserDefaultsViewerSettingsRepository.swift
├── Utils/
│   ├── Preference.swift                  ← @Preference wrapper
│   ├── GestureBlocker.swift              ← GestureRequirementLink
│   └── GestureLayer/
│       ├── GestureDescriptor.swift       ← GestureTap(CGPoint), GesturePan, GesturePinch
│       ├── GestureLayerView.swift        ← UIView с hitTestHandler
│       ├── GestureLayerCoordinator.swift ← recognizers, update in-place, wireTapChain
│       ├── GestureLayer.swift            ← UIViewRepresentable + @resultBuilder + .gestureLayer()
│       └── ZoomControl.swift             ← zoom(to:screenAnchor:animated:), reset(animated:)
└── Modules/PhotoViewer/
    ├── PhotoViewerView.swift             ← modeView → .strip → StripView
    ├── PhotoViewerViewModel.swift
    ├── PhotoViewerAssembly.swift
    ├── ZoomableImageView.swift           ← externalControl: ZoomControl, onZoomScaleChange
    ├── CompassView/
    │   ├── SwipeCompassView.swift
    │   └── RingSectorShape.swift
    └── StripView/                        ← АКТИВЕН
        ├── StripView.swift               ← основная лента (бывший StripV5View)
        ├── StripCardView.swift           ← карточка (бывший StripV4CardView)
        └── StripUnderlayView.swift       ← underlay для свайпа (бывший StripV4UnderlayView)
```

---

---

## Изменения сессии 3

### GestureTap — добавлена location

`GestureTap.action: (CGPoint) -> Void` — теперь передаёт location в window-координатах (как `GesturePinch`). `GestureLayerCoordinator.handleTap` передаёт `r.location(in: r.view?.window)`.

### ZoomControl — animated параметр

`zoom(to:screenAnchor:animated: Bool = false)` — для пинча `animated: false` (continuous), для даблтапа `animated: true`. Внутри: `scrollView.zoom(to: rect, animated: animated)`.

### Анимированный zoom-in по даблтапу (StripV5)

```swift
GestureTap(count: 2) { location in
    zoomControl.zoom(to: 3, screenAnchor: location, animated: true)
}
```

`zoomScale` ведётся через `onZoomScaleChange` от `scrollViewDidZoom` — overlay появляется плавно по мере анимации UIScrollView.

**Важно**: UIKit вызывает `scrollViewDidZoom` СИНХРОННО при `zoom(to:animated:true)` — меняется модель, анимируется только presentation layer.

### Анимированный zoom-out по даблтапу

```swift
onZoomScaleChange: { scale in
    withAnimation(scale == 1 ? .easeInOut(duration: 0.25) : nil) {
        zoomScale = scale
    }
}
```

Без `withAnimation` overlay пропадал резко (model layer меняется мгновенно). С `withAnimation` opacity анимируется параллельно с UIScrollView (~0.25s совпадает со стандартным UIKit duration).

### Фикс начального scroll position

**Проблема**: `onAppear` ставил `activeId` после того, как SwiftUI уже выставил начальный offset → лента открывалась на N-1 вместо N.

**Решение**: `onChange(of: viewModel.currentIndex, initial: true)` стреляет в первый render pass, до layout:

```swift
.onChange(of: viewModel.currentIndex, initial: true) { old, _ in
    if old == viewModel.currentIndex {
        activeId = viewModel.currentPhoto.id          // без анимации (initial)
    } else {
        withAnimation(.easeInOut(duration: 0.25)) {
            activeId = viewModel.currentPhoto.id
        }
    }
}
```

`onAppear` оставлен только для `UIScrollView.appearance().decelerationRate = .fast`.

---

## GestureLayer — архитектура (сессия 2)

Декларативный слой жестов поверх UIKit. Вешается через `.gestureLayer()` модификатор.

### Ключевые свойства

- **`captures: (CGPoint) -> Bool`** — контролирует hitTest. `true` → слой перехватывает touch, `false` → проваливается дальше по иерархии. Обновляется в `updateUIView`, всегда читает актуальный SwiftUI state.
- **`when: () -> Bool`** на каждом жесте — `gestureRecognizerShouldBegin`, более тонкая фильтрация после hitTest.
- **`require(toFail:)`** — строится автоматически: single tap ждёт провала double tap.
- **`PanFilter`** — `.horizontal`/`.vertical`/`.any`, фильтрация направления через velocity в `shouldBegin`.
- **Pinch location** — передаётся в window-координатах (для ZoomControl).

### Passthrough правило

Если `gestureLayer` вешается на карточку (descendant UIScrollView) — вертикальный пан при `shouldBegin=false` поднимается к ancestor UIScrollView и обрабатывается там. Это работает только если view — descendant, не sibling.

### ZoomControl

Bridge между `GesturePinch` на карточке и `ZoomableImageView` overlay.
- `connect(_ scrollView:)` — вызывается из `ZoomableImageView.makeUIView/updateUIView`
- `zoom(to scale:, screenAnchor:?)` — конвертирует window-координаты → imageView-координаты, вызывает `scrollView.zoom(to:rect:)`
- `reset(animated:)` — сброс зума
- `ObservableObject` для `@StateObject` в SwiftUI

---

## StripV5 — архитектура

### Состояния

| zoomScale | ScrollView | Overlay (ZoomableImageView) | gestureLayer на карточке |
|---|---|---|---|
| = 1 | active | `allowsHitTesting(false)`, alpha=0 | active (`captures=true`) |
| > 1 | `.scrollDisabled` | `allowsHitTesting(true)`, alpha=1 | inactive (`captures=false`) |

### Переход zoom=1 → zoom>1 (первый пинч)

1. `GesturePinch` на карточке владеет gesture до конца
2. `ZoomControl.zoom(to:screenAnchor:)` двигает overlay UIScrollView programmatically
3. `zoomScale = scale` → overlay становится `allowsHitTesting(true)`
4. Первый пинч заканчивается → следующий пинч нативно обрабатывает overlay UIScrollView

### Автоматический сброс зума

При смене фото (URL change) `ZoomableImageView` сбрасывает zoom → `onZoomScaleChange(1)` → `zoomScale = 1` → overlay уходит.

### StripV5 подключён к PhotoViewerView

`PhotoViewerView.stripView` → `StripV5View(viewModel:)`. StripV3, StripV4 не используются.

---

## Ключевые архитектурные решения

**Почему UIScrollView для зума, а не чистый SwiftUI:**
`MagnificationGesture` не даёт координату пинча — нельзя сделать zoom-to-point без нетривиальной математики. UIScrollView делает это нативно.

**Почему relay через hitTest, а не shouldBegin (для passthrough к sibling):**
`hitTest` работает до передачи события gesture recognizer'ам. `shouldBegin=false` не перенаправляет touch к sibling — только к ancestor. Для sibling passthrough нужен `hitTest → nil`.

**Почему lenta чистый SwiftUI:**
UICollectionView или UITableView потребовали бы ручного управления жестами для snap, zIndex, условной clip-маски. SwiftUI ScrollView с `.viewAligned` + `.scrollPosition` даёт это из коробки.

**Почему ZoomableImageView как overlay, а не nested UIScrollView:**
Два UIScrollView одновременно — конфликт жестов. В StripV5 они переключаются через `scrollDisabled` + `allowsHitTesting` — никогда не активны одновременно.

---

## Изменения сессии 4

### Баг: .scrollPosition(anchor: .center) + .viewAligned → N-1

**Симптом**: лента открывалась на фото N-1 вместо N.

**Причина**: конфликт систем выравнивания.
- `.viewAligned` снэпает по **top-edge** карточек (top item aligned to top of scroll view)
- `.scrollPosition(id:anchor:.center)` выставлял начальный offset, чтобы карточка N была по центру

Эти два offset-а **не совпадают**. Для карточки N:
- offset от `.scrollPosition(anchor:.center)` = `N × (cardH + spacing)`
- ближайший top-aligned snap-позиция `.viewAligned` для N−1 = `edgeInset + (N−1) × (cardH + spacing)`
  = `N × (cardH + spacing) + (cardH + spacing − edgeInset)` ≈ `N × (cardH + spacing) + 13pt`

Расстояние до N−1: ~13pt. Расстояние до N: ~edgeInset (~295pt). `.viewAligned` выбирал N−1.

**Фикс**: убрать `anchor: .center` из `.scrollPosition` и использовать `.contentMargins` вместо `.padding` на `LazyVStack`. При top-aligned позиционировании с content margin карточка визуально оказывается по центру — оба механизма используют одинаковый offset.

```swift
// LazyVStack — без .padding
LazyVStack(spacing: Layout.cardSpacing) { ... }
    .scrollTargetLayout()

// ScrollView
.contentMargins(.vertical, edgeInset, for: .scrollContent)
.scrollTargetBehavior(.viewAligned)
.scrollPosition(id: $activeId)  // без anchor: .center
```

### activeId инициализируется в init (вместо onChange(initial:))

Предыдущий подход с `onChange(of: viewModel.currentIndex, initial: true)` заменён на eager init:

```swift
init(viewModel: PhotoViewerViewModel) {
    self.viewModel = viewModel
    _activeId = State(initialValue: viewModel.currentPhoto.id)
}
```

Это гарантирует что `activeId` установлен до первого render pass — `gestureLayer` активен сразу, без задержки.

`onChange(of: viewModel.currentIndex)` остался для прокрутки после swipe-to-decide:

```swift
.onChange(of: viewModel.currentIndex) { _, _ in
    withAnimation(.easeInOut(duration: 0.25)) {
        activeId = viewModel.currentPhoto.id
    }
}
```

### ZoomControl: zoom(to:) переписан через setZoomScale + setContentOffset

Старый подход `scrollView.zoom(to: rect, animated:)` заменён на явное вычисление target offset:

```swift
func zoom(to scale: CGFloat, screenAnchor: CGPoint? = nil, animated: Bool = false) {
    // Предсказываем content insets после зума (совпадает с тем, что centerImageView выставит в scrollViewDidZoom)
    let newInsetX = max((scrollView.bounds.width - imageView.bounds.width * clampedScale) / 2, 0)
    let newInsetY = max((scrollView.bounds.height - imageView.bounds.height * clampedScale) / 2, 0)

    // targetOffset = newInsetX + imagePoint.x * clampedScale - pointInSV.x  (с clamp)
    scrollView.setZoomScale(clampedScale, animated: animated)
    scrollView.setContentOffset(targetOffset, animated: animated)
}
```

`setZoomScale` синхронно тригерит `scrollViewDidZoom` → `centerImageView` выставляет inset → `setContentOffset` применяется с уже правильным inset.

### Реорганизация файлов

- `StripV4/` + `StripV5/` → `StripView/`
- Версионные суффиксы удалены: `StripV4CardView` → `StripCardView`, `StripV4UnderlayView` → `StripUnderlayView`, `StripV5View` → `StripView`
- `SwipeCompassView` + `RingSectorShape` → `CompassView/`
