# Design System — контекст и план

## Статус

Ветка `feature/design-system`, worktree `romantic-jang` — **закрыта, контекст сохранён здесь**.  
Файл `Color+Tokens.swift` так и не был закоммичен. Ветка отстаёт от master на ~5 коммитов (всё что после `image_prefetch_and_cache`).

Когда возвращаться: новый worktree от актуального master, файл перенести вручную.

---

## Готовое: Color+Tokens.swift

Файл полностью спроектирован. Реализация через приватный `init(token hex: UInt32, opacity: Double = 1)`.

### Токены

| Токен | Hex | Назначение |
|---|---|---|
| `.background` | `#1a1b1f` | Основной фон приложения |
| `.surface` | `#1f2026` | Карточки, шторки, модалки |
| `.surfaceHover` | `#3a3c43` | Hover-состояния |
| `.placeholder` | `#161719` | Плейсхолдер карточки без фото |
| `.border` | `#2e2f35` | Бордеры, разделители, инпуты |
| `.textPrimary` | `#d8d9e0` | Основной текст, навбар |
| `.textSecondary` | `#9b9da6` | Заголовки карточек, даты |
| `.textTertiary` | `#4a4c55` | Метаданные, счётчики, подписи |
| `.accent` | `#2a6e40` | CTA-кнопки, активный таб |
| `.accentText` | `#a8e8bc` | Текст на accent-кнопках |

**Статусные токены — Approve:**

| Токен | Значение | Где |
|---|---|---|
| `.approve` | `#5ec97a` | Иконка/текст |
| `.approveBadgeBackground` | `rgba(#34a853, 0.15)` | Бэдж в списке |
| `.approveBadgeBorder` | `rgba(#34a853, 0.30)` | Бордер бэджа в списке |
| `.approveOverlayBackground` | `rgba(#34a853, 0.90)` | Оверлей на фото |
| `.approveOverlayText` | `#b8f0c4` | Текст оверлея на фото |

**Статусные токены — Reject:**

| Токен | Значение | Где |
|---|---|---|
| `.reject` | `#f07068` | Иконка/текст |
| `.rejectBadgeBackground` | `rgba(#ea4335, 0.13)` | Бэдж в списке |
| `.rejectBadgeBorder` | `rgba(#ea4335, 0.28)` | Бордер бэджа в списке |
| `.rejectOverlayBackground` | `rgba(#ea4335, 0.85)` | Оверлей на фото |
| `.rejectOverlayText` | `#fdb8b4` | Текст оверлея на фото |

**Статусные токены — Pending:**

| Токен | Значение | Где |
|---|---|---|
| `.pending` | `#e8c040` | Иконка/текст |
| `.pendingBadgeBackground` | `rgba(#fbbc05, 0.13)` | Бэдж в списке |
| `.pendingBadgeBorder` | `rgba(#fbbc05, 0.28)` | Бордер бэджа в списке |

---

## Текущий долг: хардкод в кодовой базе

### Decision+Presentation.swift — главная цель миграции
```swift
// Сейчас:
case .approved: .green
case .rejected: .red
case .pending:  .secondary

// После:
case .approved: .approve
case .rejected: .reject
case .pending:  .pending
```

### StatItemViewModel.swift
```swift
Color.green   → .approve
Color.red     → .reject
Color.orange  → .pending   // или отдельный токен, если нужен orange
```

### StatCardViewModel.swift — полностью захардкожены RGB
```swift
Color(red: 0.3, green: 0.5, blue: 1.0)  // approved stat — нет аналога в токенах, нужно решить
Color(red: 0.9, green: 0.5, blue: 0.3)  // rejected stat
Color(red: 0.5, green: 0.8, blue: 0.4)  // pending stat
```
Эти цвета отличаются от статусных токенов — их назначение в `StatCard` другое (графика/чарт).
Возможно нужны отдельные chart-токены, либо унифицировать со статусными.

### ProgressBarView.swift
```swift
Color(red: 0.2, green: 0.6, blue: 1.0)  // нет аналога — chart/progress токен
Color(red: 0.4, green: 0.5, blue: 1.0)
```

### PhotosetCardView.swift + PhotosetFeedView.swift
```swift
Color(.systemBackground)         → .surface
Color(.systemGroupedBackground)  → .background (или отдельный токен)
```

### PhotosetDetailView.swift
```swift
.green   → возможно .approve (контекст: прогресс-бар)
.red     → .reject (кнопка отклонения)
.white, .blue  → нет аналогов, ситуативные
```

---

## Что ещё не спроектировано

- **Typography tokens** — шрифты, размеры, weight не токенизированы
- **Spacing tokens** — padding/gap значения
- **Shape tokens** — corner radius (сейчас везде разные числа)
- **Chart tokens** — цвета для StatCard/ProgressBar (отдельная семантика от статусных)
- **Иконки** — не систематизированы (сейчас SF Symbols по месту)

---

## Архитектурный вопрос: Extension vs Asset Catalog

Текущий подход (`Color+Tokens.swift`) — Swift extensions с hex-литералами.  
Альтернатива — `.colorset` в `Assets.xcassets` (поддержка dark/light mode из коробки).

**Решение не принято.** Сейчас приложение dark-only (тёмная тема), поэтому extensions проще.  
Если появится light mode — придётся мигрировать на colorsets.

---

## Как продолжить

1. `git worktree add .claude/worktrees/design-system feature/design-system` от актуального master (ребейз или новая ветка)
2. Перенести содержимое `Color+Tokens.swift` (см. выше или `/design-system` скилл)
3. Закоммитить токены как `feat: add color tokens`
4. Последовательно мигрировать: `Decision+Presentation.swift` → `StatItemViewModel` → остальное
5. Каждый файл — отдельный `refactor:` коммит
