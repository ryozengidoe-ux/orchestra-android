# PATCHES.md — наши отличия от оригинала NeiP4n/orchestra-app

Оригинал — только read-only референс, его не трогаем вообще.
Все правки — в рабочей копии `~/workspace/orchestra-src/`.
При каждой синхронизации с апстримом (v2.3) этот список применяется заново,
механически, по пунктам ниже.

Синхронизация 06.11.2026: апстрим подтянут до коммита `827fb10`
(merge `39945ca8`: B5 rate limit / error taxonomy / escalation;
`df38edf`: B2+B3+B13 autoloop event journal, decide/cards/tick,
server password, CORS, SSRF block; `5dedd19`: B0+B1 photon patch,
typecheck fixes, serve grey-screen fix; `e9cf403`: desktop capture
за ORCHESTRA_DESKTOP_CAPTURE). База до мержа — `329881c9`.
Мерж и патчи зафиксированы в `/tmp/orchestra-upstream`
(коммит `a7103ea` — local patches поверх мержа).

## 1. Photon-node удалён (сборка)

- `package.json`: удалена зависимость `@silvia-odwyer/photon-node`
  (протухший патч, ломал `bun install`).
- `patches/@silvia-odwyer%2Fphoton-node@0.3.4.patch`: файл удалён.
- Проверка: `grep -c photon package.json` → 0.

## 2. `_assets` → `webassets` (AGP отбрасывает папки на `_`)

- `packages/app/vite.config.ts:50`: `assetsDir: "_assets"` → `"webassets"`.
  Иначе AGP `mergeDebugAssets` молча выбрасывает весь JS/wasm из APK
  (доказано пробой `_testdir` vs `testdir2`; APK собирался без кода —
  23 файла вместо 1698).
- `packages/app/vite.pwa.ts:32`: `navigateFallbackDenylist` —
  `(?:webassets|assets)` вместо `(?:_assets|assets)`.

## 3. Мобильные оверрайды v2.2 (только ≤767px)

- Новый файл `packages/app/src/mobile-overrides.css` (59 строк):
  textarea/input/select 16px (авто-зум iOS), текст 13→14px,
  12→13px, 11→12px, меню/строки сессий/кнопки композера min 44px,
  диалоги `dvh` вместо `vh`.
- `packages/app/src/index.css`: `@import "./mobile-overrides.css";`
  в конце + `#root` → `height: 100vh; height: 100dvh;` (dvh с фолбэком).
- Источник: `v2.2-audit.md` (18 проблем). №4 (кламп 450px) отклонён —
  тесты фиксируют минимум как намеренный.
- Проверка в бандле: в `dist/webassets/index-*.css` есть
  `width<=767px`, `100dvh`, `min-height:44px`, `font-size:16px`.

## 4. Наши файлы поверх апстрима (не патчи, а добавления)

- `PLAYBOOK.md` — наш файл в корне копии.
- `run_*.py` (`run_klinch.py`, `run_anymodel.py`, `run_service_klinch.py`
  и др.) — наши helper-скрипты запуска серверов, в апстриме их нет.
- `bun.lock` отличается от апстримного (локальная установка без photon-node).

## 5. Android-проект (отдельно, не в копии апстрима)

- `~/workspace/orchestra_android/` — проект с нуля по образцу
  `packages/android` оригинала, пакет `ai.neurosignal.orchestra`.
  Свои фиксы `app/build.gradle.kts` (Gradle 9.6), манифеста
  (`densityDpi` убран из configChanges; `<queries>` — один `<intent>`
  на схему: https/http/mailto разнесены по трём `<intent>`,
  иначе парсер отклоняет APK при установке —
  INSTALL_PARSE_FAILED_MANIFEST_MALFORMED, найдено прогоном CI
  42193094370), флага `android.sourceset.disallowProvider=false`,
  пути ассетов `generated/webAssets/app` + `exclude("**/*.map")`.
  Подробности — в `WORK_LOG.md` и `~/AGENTS.md`.

## Как повторить синхронизацию

1. `git clone` / `git pull` оригинала во временную папку
   (например `/tmp/orchestra-upstream`), НЕ в `orchestra-src/`.
2. Применить пункты 1–3 выше к копии.
3. `bun install && bun run build` в копии, проверить оверрайды в dist.
4. Собрать release-APK (`scripts/build-release.sh`), проверить на диске.
5. Обновить этот файл (коммит апстрима + дату) и WORK_LOG.md.
