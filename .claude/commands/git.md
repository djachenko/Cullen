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
- Императив: *Add*, *Fix*, *Refactor* — не *Added*, не *Fixing*

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

## .gitignore обязательные записи

```
.claude/worktrees/
.claude/settings.local.json
```
