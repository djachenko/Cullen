---
description: Apply when the task touches the Python CLI companion, culled.json, or how decisions get applied to files on disk
---

# Python CLI (cullen-cli)

CLI живёт в отдельном репозитории: https://github.com/djachenko/cullen-cli (`~/projects/cullen-cli`). Здесь — только контракт между приложением и утилитой.

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

Категории — произвольные ключи, значения — стемы файлов. Пишет `ExportDecisionsUseCase`. Изменение формата — правка в обоих репо.

## Команды

```
cullen cull [PATHS...] [--file culled.json]   # разложить сорсы по папкам-категориям
cullen flop PATH [FILE] [--dry-run]           # поднять папки-категории обратно
cullen relocate PATH [ROOT]                   # найти экспортированные json и разнести по фотосетам
```
