# Python CLI (cullen.py)

Расположение: `CLI/src/cullen/cullen.py`  
Запуск: `python cullen.py [path] [file_name]`

## Что делает

Читает `cullen.json` из папки фотосета и раскладывает файлы по папкам по решениям.

**Алгоритм**:
1. Сначала поднимает все файлы из подпапок решений обратно в корень (`move_up`)
2. Затем раскладывает файлы по папкам согласно маппингу из `cullen.json` (`move_down`)

## Аргументы

```bash
python cullen.py [path] [file_name]
# path     — путь к папке фотосета (по умолчанию: cwd)
# file_name — имя JSON-файла с решениями (по умолчанию: cullen.json)
```

## Формат cullen.json

```json
{
  "decisions": {
    "approved": ["DSC_0001", "DSC_0003.jpg"],
    "rejected": ["DSC_0002", "DSC_0005.jpg"]
  }
}
```

Суффикс `.jpg` у стемов опциональный — `removesuffix(".jpg")` применяется при маппинге.

## Зависимости

- `typer` — CLI фреймворк
- `justin_utils` — внешняя библиотека с `Exif`, `parse_exif` (используется в `sources.py`)

## sources.py

Вспомогательный модуль для работы с файлами-источниками (пока не подключён к основному CLI):

- `InternalMetadataSource` — JPEG, TIFF, DNG, HEIC (метаданные внутри файла)
- `ExternalMetadataSource` — RAW + XMP (NEF, RAF, ARW + sidecar)
- `parse_sources(seq)` — парсит список файлов в список Source-объектов

## Планируемые улучшения (из backlog)

- Матчинг по имени файла (основной режим) — текущий
- Матчинг по индексу — для VK где имена файлов потеряны
- `--dry-run` режим — показывает что будет сделано без реального перемещения
- Перемещение в `approved/` и `rejected/` (сейчас имя папки берётся из ключей JSON)
