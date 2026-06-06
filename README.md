# Кабиторий

Личный кабинет и каталог услуг как **конструктор**, встраиваемый в конфигурацию 1С на БСП. МФЦ/Госуслуги-паттерн: каталог → заявка → обработка → результат. Тонкий React-клиент для клиентов; сотрудники работают в 1С.

> Статус: ранняя стадия. Архитектура устоялась (baseline), реализация впереди.

## Документы
- **[konspekt.md](konspekt.md)** — архитектура, source of truth (что и какие ограничения).
- **[CLAUDE.md](CLAUDE.md)** — как работать в репозитории (инварианты в коде, рецепты).
- **[docs/onboarding.md](docs/onboarding.md)** — три ментальных сдвига для 1С-разработчиков.

## Структура
```
konspekt.md        архитектура (source of truth)
CLAUDE.md          соглашения и рецепты реализации
1c/
  extension/       форма «расширение» (встраивается в хост-конфигурацию)
  standalone/      форма «самостоятельное приложение на БСП»
frontend/          тонкий React-клиент + Dockerfile
deploy/            менеджмент-скрипт: deploy / update / remove
docs/              → MkDocs (+ onboarding.md, reglament/)
roadmap/
```

## Сборка и тесты
- **Тесты** (YAxUnit, ядро): `bash scripts/run-tests.sh` — см. `1c/standalone/tests/README.md`.
- **Релизы** (`.cf`/`.cfe` в GitHub Releases): `bash scripts/build-release.sh <tag>` — собирает из исходников и публикует. Требует локальную платформу 1С (путь в `.v8-project.json`).
- Готовые сборки: [Releases](https://github.com/iMironRU/kabitoriy/releases).

## Запуск
TBD — появится вместе с первой рабочей сборкой (`deploy/`).

## Лицензия
- **Код** (`1c/`, `frontend/`, `deploy/`) — софтверная лицензия, см. `LICENSE` (не финализирована; рекомендация Apache-2.0, для share-alike — AGPL-3.0).
- **Документация** (`konspekt.md`, `CLAUDE.md`, `docs/`, `roadmap/`) — CC BY-SA 4.0, см. `LICENSE-docs`.

## Автор
Александр (iMironRU). Блог: imiron.ru · Telegram: @blog_imiron · контакт: @iMironRU
