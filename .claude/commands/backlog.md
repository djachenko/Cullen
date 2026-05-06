# Backlog — текущий фокус

## В работе прямо сейчас

### ResetDecisionUseCase ⏳
Сейчас `resetDecision()` пишет `.pending` — временный хак. Нужно:
1. `remove(photoId:for:)` в `DecisionsRepository` протоколе
2. Реализовать в `JsonDecisionsRepository`
3. `ResetDecisionUseCase` протокол + реализация в `DecisionsUseCaseImpl`
4. Зарегистрировать в `UseCasesAssembly` через `.implements()`
5. Подключить в `PhotoViewerViewModel`

### Фильтрация в PhotosetDetail ⏳
`activeFilters` и `filteredPhotos` временно убраны — были завязаны на `photo.decision` которого больше нет. Восстановить фильтрацию по `PhotoGridCellViewModel.decision` после построения контента. Три тогла (approved/rejected/pending), состояние — в памяти (сессия).

### Счётчики в PhotosetFeed 🔄
Карточка не обновляется после возврата с детали — пересоздаётся при скролле. Реальные счётчики уже считаются, но обновление не реализовано.

### Спиннеры — нет индикации загрузки 🐛
Отсутствует или не работает везде, особенно в деталях фотосета.

---

## Следующий эпик: JsonBundleConnector

Разбить `cullen_2.json` на отдельные файлы по фотосету + обновить `index.json`. `JsonPhotosRepository` менять не нужно — архитектура готова.

После — `ExportDecisionsUseCase`: разбить на стратегии (сейчас принимает `PhotosetsRepository` хотя нужен только для VK).

---

## Технический долг — мелочи

- `syncStatus` в `JsonPhotosRepository.toDomain()` — убрать `randomElement()`, поставить `.synced`
- `Collection+KeyPath` в `SwipeDirection.swift` — перенести в `Extensions/`
- `__trash/BottomBar.swift` и `__trash/NavBar.swift` — удалить
- `NavigationBackSwipeDisabler` в `PhotoViewerView.swift` — удалить
- Миграции: прописать стабильные ключи когда формат данных стабилизируется
- `MockPhotosetsRepository` — добавить заглушки для `getPhotosetIds()` и `getPhotoset(id:)`

---

## Крупные эпики в очереди (по приоритету)

1. **Коннекторы & Источники данных** — `/connectors`
2. **Оффлайн & Prefetch** — `/prefetch`
3. **Миграция на @Observable** — `/observable`
4. **UI компоненты** — фильтры, SegmentedProgressBar, CullenNavigationBar, Toolbar-меню
5. **Теги** — расширение Decision
6. **SPM пакеты** — CullenUI, SwiftFoundationExtensions, CullenDesignSystem — `/spm`
7. **Дистрибуция** — AltStore, индикатор подписи — `/distribution`

## CLI

- **Мигрировать build backend на hatchling** — сейчас setuptools, hatchling не требует явного `packages.find` для `src/` layout

Полный бэклог: `backlog.md` в корне проекта.
