---
description: Apply when creating branches, making commits, merging, or working with worktrees
---

# Git: workflow и соглашения

## Модель: GitHub Flow

Один постоянный `master`. Все фичи, рефакторинги и чоры — в отдельных ветках.

```
master ──────────────────────────(M)────────── master
            └── feature/xxx ────┘
```

**Правила:**
- Ветка всегда стартует от актуального `master`
- Ветки не зависят друг от друга. Если фича Б требует код фичи А — сначала мёрдж А в master, потом ветка Б от нового master
- Мёрдж в master — всегда `--no-ff` (обязательный merge commit)
- Подтянуть изменения master в ветку — `git merge master` (не rebase)

## Именование веток

```
feature/<name>   # новая функциональность
refactor/<name>  # рефакторинг без изменения поведения
fix/<name>       # исправление бага
chore/<name>     # инфраструктура, документация, зависимости
```

Примеры: `feature/swinject-augmentations`, `refactor/code-cleanup`, `chore/claude-skills`

## Semantic commits

Формат: `<type>: <что сделано>`

| Тип | Когда |
|---|---|
| `feat` | новая функциональность |
| `fix` | исправление бага |
| `refactor` | изменение кода без изменения поведения |
| `chore` | сборка, зависимости, конфиги, документация |
| `style` | форматирование, переименования без смысловых изменений |
| `test` | тесты |
| `revert` | откат коммита |

```
feat: Implemented autoscroll to next unculled photo
fix: Fixed scroll reset error
refactor: Refactored photoset model
chore: Add CLAUDE.md: project overview, stack, architecture
style: Dropped redundant imports
```

**Правила:**
- Строчная буква после `:`
- Без точки в конце
- Без `Co-Authored-By:` и других мета-строк от инструментов
- Императив, совершенный вид: *Added*, *Fixed*, *Refactored* — не *Add*, не *Adding*, не *Fixing*

## Автор

Все коммиты — один автор, прописан в локальном конфиге репозитория:

```bash
git config user.name "Igor Djachenko"
git config user.email "i.s.djachenko@gmail.com"
```

## Слияние ветки в master

```bash
git checkout master
git merge --no-ff feature/xxx -m "Merge branch 'feature/xxx'"
```

Сообщение merge-коммита — стандартное `Merge branch '<name>'`. Не изобретать.

## Старые ветки

Не удалять — переносить в `archive/`:

```bash
git branch -m feature/old-messy archive/feature/old-messy
```

## Worktrees

Активные рабочие деревья — в `.claude/worktrees/` (в `.gitignore`).  
Создать: `git worktree add .claude/worktrees/<name> -b <branch>`  
Удалить: `git worktree remove .claude/worktrees/<name> --force`

Переключить worktree на другую ветку — через `git -C .claude/worktrees/<name> checkout <branch>`. Если есть незакоммиченные изменения — сначала уточнить у пользователя, что с ними делать. Не стэшить самовольно.

## Переписывание истории

### Параллельная ветка для ревью

Перед переписыванием создавать копию с префиксом, не трогая оригинал:

```bash
git checkout -b clean/master   # копия master для переписывания
# ... правки ...
# После ревью:
git checkout --detach
git branch -m clean/master master
git checkout master
```

Оригинальные ветки остаются нетронутыми до явного подтверждения.

### rebase --rebase-merges

Для переписывания истории с сохранением топологии веток:

```bash
GIT_SEQUENCE_EDITOR=/tmp/editor.sh git rebase -i --root --rebase-merges
```

Команды в todo: `pick`, `reword`, `exec`, `drop`, `squash`. `exec` удобен для `git commit --amend --no-edit -m "new message"` вместо reword (не открывает редактор).

Для split коммита в todo: `pick <hash>` + `exec bash /tmp/split.sh`. В скрипте: `git reset HEAD~`, потом `git add <files> && git commit`.

### filter-repo

Вычистить файл из всей истории + переименовать автора:

```bash
git filter-repo \
  --path path/to/file --invert-paths \
  --mailmap /tmp/mailmap.txt \
  --refs refs/heads/<branch> \
  --force
```

Формат mailmap: `New Name <email> Old Name <email>`

После filter-repo checked-out worktree может оказаться на detached HEAD — нужно вернуть ветку вручную.

### Ребейз ветки поверх переписанного master

Если ветка `feature` ответвилась от старого master, а нужно её перенести на новый:

```bash
git rebase -i --onto new-master <old-base-commit> feature
```

`<old-base-commit>` — последний общий коммит старой ветки с master (результат `git merge-base feature master`).

## .gitignore обязательные записи

```
.claude/worktrees/
.claude/settings.local.json
```
