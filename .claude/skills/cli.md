---
description: Apply when the task touches the Python CLI companion, culled.json, or how decisions get applied to files on disk
---

# Python CLI (cullen-cli)

CLI живёт в отдельном репозитории: https://github.com/djachenko/cullen-cli (`~/projects/cullen-cli`, команды — `cullen-cli/README.md`). Здесь — только контракт между приложением и утилитой.

## Контракт: `culled.json`

Приложение экспортирует, CLI читает. Лежит в корне фотосета.

```json
{
  "name": "26.03.22.fen_init_lab",
  "decisions": {
    "good": ["ZSC_2541", "ZSC_2542"],
    "bad": ["ZSC_2543"]
  }
}
```

Категории — произвольные ключи, значения — стемы файлов **без расширения** (`entry.name` из индекса). Пишет `ExportDecisionsUseCase`. Изменение формата — правка в обоих репо.

**`name` — это `String(describing: photosetId)`, не `photoset.name`.** Совпадают, пока `JsonPhotosRepository` отдаёт `.string(filename)`; источник с `.int`/`.uuid` сломает `cullen relocate`. Открытый риск, известен обеим сторонам.
