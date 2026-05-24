---
description: Apply when working on SPM packages: CullenUI, SwiftFoundationExtensions, or CullenDesignSystem
---

# SPM Пакеты

## CullenUI — библиотека UI компонентов

Локальный SPM пакет. Кандидаты для переноса:
- `CullenNavigationBar` — кастомный Large Title (перенести после реализации)
- `SegmentedProgressBarView` — после рефакторинга из `ProgressBarView`
- `PhotoFilterView` — standalone компонент фильтрации
- `SwipeCompassView`
- `ZoomableImageView`

## SwiftFoundationExtensions — библиотека расширений

Локальный SPM пакет. Перенести из `Extensions/`:
- `CGPoint+Extensions`
- `Comparable+Extensions`
- `Strideable+Extensions`
- `Collection+KeyPath` из `SwipeDirection.swift` — сейчас лежит временно там

## CullenDesignSystem

Локальный SPM пакет. Типизированные дизайн-токены:
- `Spacing`
- `Radius`
- `Typography`
- `Icons`
- `Colors`

Заменить захардкоженные значения по всем View после создания пакета.
