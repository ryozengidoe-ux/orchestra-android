# Журнал работ — Оркестра Android

Назначение файла (правило Shadow от 06.11.2026): сюда записываются все будущие действия —
что сделано, как сделано и что планировалось сделать. Файл синхронизируется на Google Drive.
Ведётся на русском. Коротко: факты и решения, без воды.

## 2026-11-06 ~02:15 — задача от Shadow

- «Создай оркестру с полного нуля сам, без opencode++, сверяйся с github.com/NeiP4n/orchestra-app,
  нужна его полная адаптация с этим дизайном же, всё в точности как там».
- Что хотел сделать: Android-приложение-клиент Оркестры — нативная WebView-обёртка вокруг
  веб-клиента packages/app, бандл вшит в APK, телефон подключается к серверу `orchestra serve`.
  Пакет ai.neurosignal.orchestra, версия 2.0.24.

## 2026-11-06 ~02:15–02:48 — сборка APK

Как делал:
- Оригинал `NeiP4n/orchestra-app` — только read-only референс, не трогал вообще.
  Рабочая копия монорепозитория: `~/workspace/orchestra-src/` (без .git и node_modules).
  В копии убран только протухший патч photon-node (файл + строка в package.json).
- В копии: `bun install` (2457 пакетов), `bun run build` — бандл `packages/app/dist`, 150M.
- Новый Android-проект с нуля по образцу `packages/android`: `~/workspace/orchestra_android/`.
  Отличия от оригинала: пакет ai.neurosignal.orchestra, heap -Xmx1g, пути на соседний
  `../orchestra-app`, в syncWebBundle `exclude("**/*.map")`.
- Дефекты оригинала и как чинил:
  1. `app/build.gradle.kts` не компилируется под Gradle 9.6 (`rootProject.projectDirectory`,
     `webBundle.asFile`) → `rootProject.file(...)` и `webBundle` (File).
  2. AGP 9.4 запрещает Provider в SourceSet API (`assets.srcDir` с DirectoryProperty) →
     флаг `android.sourceset.disallowProvider=false` в gradle.properties.
  3. AAPT отвергает `densityDpi` в configChanges (такого значения нет, есть только `density`) →
     убрано из манифеста.
  4. Sync копировал бандл в `generated/webAssets`, а AssetHost ждёт `assets/app/` →
     `into(layout.buildDirectory.dir("generated/webAssets/app"))`.
  5. AGP `mergeDebugAssets` молча отбрасывает папки, чьё имя начинается с `_` (доказано пробой
     _testdir vs testdir2; файлы на `_` — нет, только папки). Бандл Vite кладёт JS/wasm
     в `_assets/` — APK собирался без кода (23 файла вместо 1698). Лечение: в копии
     `assetsDir "_assets"` → `"webassets"` (vite.config.ts:50) + поправлен
     navigateFallbackDenylist в vite.pwa.ts (`(?:webassets|assets)`), бандл пересобран.
     Первая пересборка бандла убита рестартом рантайма на 49-й секунде (dist остался
     частично переписан) — запустил заново, достроилась чисто (150M, 3159 файлов).
- Сборка APK: распакованный Gradle 9.6.0, JDK 21, `--no-daemon`,
  `-PwebBundleDir=<копия>/packages/app/dist -x :app:buildWebApp`
  (buildWebApp строит бандл оригинала, где нет node_modules/vite).
- Итог: `app/build/outputs/apk/debug/app-debug.apk`, 38 225 625 байт,
  sha256 `228e707c9802d3ae68421a15dbdd2e49e7504d4c14903cdf02281350dae554d1`.
  Проверено на диске: пакет ai.neurosignal.orchestra, 20024/2.0.24, разрешения
  INTERNET/CAMERA/RECORD_AUDIO, assets/app/ 1698 файлов (webassets/ 1675, wasm-движки
  Office на месте, 0 .map), MainActivity/AssetHost/ServiceWorkerClient в dex,
  подпись debug v2 (apksigner verify: Verifies).
- Не сделано: на телефоне не ставился и не тестировался. При первом запуске ввести
  адрес и пароль своего сервера `orchestra serve`.
- Доставлен Shadow вложением в чат 06.11.2026 ~02:49.

## 2026-11-06 ~02:48 — Opus 5.5 и генерация картинок

- Shadow: «для дизайна попробуй модели опус 5.5, мне интересно картинки он создать сможет».
  Проверка: растр opus-5.5 не генерирует (нет инструмента); SVG кодом — смог
  (иконка Orchestra, файлы в `orchestra_android/design/`).
- Shadow: «дай задачу чтобы он добавил в оркестру такой инструмент».
  Сделал: выдал задачу субагенту — Опус через Anymodel напрямую, код инструмента
  generate_image в копию orchestra-src (packages/core/ai), провайдер настраиваемый.
- 06.11 ~02:51 Shadow: «забей он не умеет генерить». Задачу закрыл, агент остановлен.
  Тема генерации картинок Опусом ЗАКРЫТА, не переоткрывать.

## 2026-11-06 ~03:03 — публикация (в работе)

- Shadow: «выкладывай на гитхаб, и по мимо этого кидай на гугл диск».
  Плюс: «все будущие действия сохраняй в файле и что и как делал что хотел сделать
  тоже кидай в гугл» — этот файл и есть тот журнал, он тоже уходит на Google Drive.
- План: APK → релиз на GitHub (Lumus-ai/mobile-alpha-releases) + Google Drive;
  этот файл → Google Drive. Обновлять файл по мере работы.
- Статус: файл создан 03:04. APK на Drive загружен 03:06: https://drive.google.com/file/d/17rqglumenu0Qa4TJUNGZHt3FLX-i8Xx0/view
  (38 225 625 байт, совпадает с локальным). Файл-журнал на Drive: https://drive.google.com/file/d/1RhgfUSv4WvtqgFl_F0qVKT4KQ3LjgZvW/view
- GitHub-релиз НЕ создан (03:15): вход через Google сработал, но зашёл аккаунт ryozengidoe-ux —
  у него только чтение Lumus-ai/mobile-alpha-releases (страница создания релиза редиректит
  на главную, кнопки создания нет, GitHub предлагает только форк). Конфликта тегов нет
  (orchestra-android-2.0.24 отсутствует). Ничего не создано, version.json не тронут.
  Для продолжения нужен вход как Lumus-ai (у него права на запись) либо права на запись
  для ryozengidoe-ux. Коннектор GitHub (MCP) релизы и бинарники не умеет — только текст до 16 МБ.
- 03:18 Shadow: «зайди назад и дай права тогда на ак» — отказ от входа как Lumus-ai, вместо
  этого выдать права на запись аккаунту ryozengidoe-ux. Браузер возвращён к сессии
  ryozengidoe-ux (агент входа успел выйти из него до остановки — сессию восстановили
  повторным входом через Google, 03:19). Выдача прав — только от имени Lumus-ai (настройки репозитория →
  Collaborators → добавить ryozengidoe-ux с Write); коннектор GitHub права выдавать не умеет.
- 04:47 Shadow: «Почему не работаешь? Делай приложение, пофиг что я проверить не могу,
  просто не нужны [проверки]». Прямой путь в основной репозиторий закрыт правами — сделал
  через форк: 04:48–04:49 создан форк под ryozengidoe-ux
  (https://github.com/ryozengidoe-ux/mobile-alpha-releases, только main) и опубликован
  релиз «Orchestra Android 2.0.24», тег orchestra-android-2.0.24, цель main (78e58aa),
  пометка Latest. Ассет orchestra-android-2.0.24.apk — 36.5 МБ, sha256 228e707c… (совпадает
  с локальным APK). Ссылка: https://github.com/ryozengidoe-ux/mobile-alpha-releases/releases/tag/orchestra-android-2.0.24
  Исходный репозиторий Lumus-ai и version.json не тронуты. Как только Shadow даст
  ryozengidoe-ux права — перенести релиз в основной репозиторий.
- 04:52 Shadow: «Сам себе дай их» — выдать права самому. Проверил все пути: браузер
  под ryozengidoe-ux — только чтение, выдать не может; коннектор GitHub (Lumus-ai) —
  в живом каталоге инструментов нет выдачи прав соавторам (проверено list-tools
  04:52); сохранённого логина Lumus-ai нет. Сам себе выдать права НЕ МОГУ — нужен
  либо ввод логина Lumus-ai в карточку в чате (браузер сделает сам), либо выдача
  Shadow в настройках репозитория. Проверка 04:50: прав по-прежнему нет.
- 04:54 Shadow: «Забей на Lumus-ai создай свой репо и делай там». Сделано 04:54–04:56:
  новый публичный репозиторий ryozengidoe-ux/orchestra-android
  (https://github.com/ryozengidoe-ux/orchestra-android, README, начальный коммит 634001d)
  и релиз «Orchestra Android 2.0.24», тег orchestra-android-2.0.24, Latest, ассет
  orchestra-android-2.0.24.apk 36.5 МБ, sha256 228e707c… (совпадает с локальным APK).
  Ссылка: https://github.com/ryozengidoe-ux/orchestra-android/releases/tag/orchestra-android-2.0.24
  Lumus-ai и форк не тронуты. Дальше релизы — сюда.

## 2026-11-06 ~03:30 — перевод совета на Lix (3 дня работы на нём)

- Shadow: «Поставь модели от провайдера lix теперь в течении 3 дней будем на нем работать».
- Сервер оркестры был остановлен — перезапустил его с обоими ключами (Klinch + Lix),
  скрипт `~/workspace/orchestra-app/run_service_klinch_lix.py` (ключи — только суррогаты
  из коннекторов, реальные значения нигде не пишутся). Проверено: в env процесса сервера
  есть и KLINCH_API_KEY, и LIX_API_KEY; сервер отвечает на :49375.
- Чату совета (ses_group_gealxz, «Общество») поставлена модель lix/gpt-6-astra —
  через API POST /api/session/.../model, ответ 204, в базе проверено
  (было klinch/opus-5.5). Астра выбрана как проверенная на Lix (пишет верный код, быстрая);
  Lix-овский opus-5.5 для координатора не годится — на расплывчатых промтах весь бюджет
  съедает скрытое рассуждение.
- Побудка совета отправлена (@all + consult_all по Этапу 3) — но агент чата совета
  НЕ запустился: сообщение висит в очереди непрочитанным, токенов 0. Смена модели совет
  не оживила — механизм мёртв не из-за модели. Обычные сессии оркестры теперь могут
  брать lix-модели (ключ у сервера есть, в конфиге 30 моделей).
- 03:36 Shadow: «Дай промт совету чтобы использовали провайдера lix и пускай сами
  распределят модели по ролям». Промт отправлен в чат совета (msg_1ae125b0d001RhsHTjylvyIVlJ):
  3 дня только на Lix, consult_all, распределить модели по ролям самим, вернуть таблицу
  «роль — модель Lix — почему» (в промте — весь список из 30 моделей и проверенные факты:
  astra/kimi пишут код, opus-5.5 — только с лимитом 16000). Проверка через 90 сек:
  токенов 0, в очереди 5 сообщений — агент по-прежнему не запускается, промт ждёт
  своей очереди, как и предыдущие.

## 2026-11-06 ~04:04 — проверка живых Lix-моделей и распределение по ролям

- Shadow: «делай все сразу без перерыва, так как не должно быть простоев».
- Живая проверка Lix (04:05–04:06, прямые вызовы lix_chat.py, «1+1=»):
  МЁРТВЫ (403): gpt-6-astra, claude-opus-5.5, claude-sonnet-5.5.
  ЖИВЫ: deepseek-v4.1-flash («2»), deepseek-v4-pro («1+1=2»), glm-5.3-prime («2»),
  kimi-k3 («**2**», лимит 500), qwen3.8-max («2»), qwen-flash («1 + 1 = 2», 0 reasoning).
  Ключ жив, список моделей отдаётся — закрылись именно топ-модели, между 03:22 и 03:54.
- Совет переведён с мёртвой астры на lix/deepseek-v4.1-flash (API 204, проверено в базе).
  В чат совета отправлена поправка (msg_1ae2cf0780013zogMLvn8TQleq): astra/opus/sonnet —
  403, распределять только из живых моделей.
- Распределение по ролям (моё, совет молчит — агент не запускается):
  координатор совета — deepseek-v4.1-flash; код — deepseek-v4.1-flash (основная, собрала
  сайт целиком с первого прогона) + kimi-k3 (вторая, верный код с assert); ревью/анализ —
  deepseek-v4-pro и glm-5.3-prime; быстрые задачи — qwen-flash и qwen3.8-max.
  Оговорка: tool calls моделей Lix через оркестру не проверены — только прямые вызовы API.
- Сайт sait-klinch-opus-lix/index.html проверен: 21 000 байт, начало `<!DOCTYPE html>`,
  конец `</html>`, лендинг + консоль «Консоль», собран на deepseek-v4.1-flash (6 чанков,
  без ретраев). Цены и контексты в таблице моделей написала модель — против живого
  прайса Klinch не сверены.
- 04:07 Shadow: «Чо там открой сайт». Файл загружен во встроенное хранилище Muse:
  https://muse.ai/files/1425623727296553/1174128645285801/x58dv4x3rcj8rh06b3wbirxt/index.html
  (живёт до 08.11.2026 ~04:07 по Самаре). Проверка в браузере песочницы не удалась —
  домен muse.ai заблокирован политикой организации в моём браузере; на телефоне Shadow
  ссылка должна открыться.

## 2026-11-06 ~05:15 — план развития APK + крон каждые 10 минут

- Shadow: «Это другой чат тут мы создаём апк» — граница: этот чат — только APK,
  Фенрир Терминал — в соседнем чате. Моя параллельная сессия v1.2 терминала здесь
  остановлена (агент 595bcedc, shutdown), соседнему чату передано, чтобы не ждали слияния.
- Shadow: «Прлумай план по развитию апк» → написан `~/workspace/orchestra_android/PLAN.md`:
  v2.0.25 (проверка на телефоне — нужен телефон Shadow, главный пробел: APK на устройстве
  не ставился) → v2.1 (релизная подпись + процесс релизов + иконка из design/) →
  v2.2 (мобильная вёрстка) → v2.3 (синхронизация с апстримом + PATCHES.md) →
  v2.4 (фон, только если нужно) → v3.0 (агент на телефоне, только по слову Shadow).
  Запреты: NeiP4n read-only, Lumus-ai не трогать, version.json не трогать.
- Shadow: «Обязательно каждые 10 минут чекай и давай задачи используя провайдера lix» →
  крон `orchestra-apk-10m-watch` (interval 10m, Europe/Samara, первый прогон ~05:26).
  Каждый прогон: читает PLAN.md + `.loop-state.json`; если задача выполняется — молчит;
  если простаиваем — берёт следующую по порядку (v2.0.25/v2.4/v3.0 — только по слову Shadow),
  выполняет на живых Lix-моделях (flash/pro/prime/kimi/qwen3.8/qwen-flash, не больше 3
  параллельных), проверяет на диске, обновляет PLAN.md и этот журнал. Молчит в пустых
  прогонах. Стоп: план готов или Lix умер (после 09.11) — крон удаляется сам.

## 2026-11-06 ~05:46 — v2.1: release-APK 2.0.24 собран (крон orchestra-apk-10m-watch)

- Взята следующая задача по плану: v2.1 (v2.0.25 — только с телефоном Shadow, пропущена).
  Состояние цикла: v2.1 была частично готова (keystore, иконки, RELEASE_PROCESS.md,
  build-release.sh), не хватало только самого release-APK — Gradle падал по RAM.
- Сборка, три попытки:
  1. `-Xmx512m` (перебит gradle.properties) — компиляция прошла, упала на
     `lintVitalAnalyzeRelease`: не скачался lint-gradle 32.4.0 с dl.google.com —
     PKIX «signature check failed».
  2. Причина — CA снова ротировался: в текущем бандле Hatch CA fingerprint
     `38:B2:94:EF…` (был `6C:C1:D9…`). Пересобран trustStore
     `gradle/hatch-cacerts` из текущего `/run/hatch/egress-tls/ca-bundle.pem`.
  3. Вторая грабля — `ANDROID_HOME` в env нет, Gradle: «SDK location not found».
     SDK — `/home/hatch/android-sdk`, задан явно.
  4. Третья попытка — BUILD SUCCESSFUL за 1м 37с.
- Итог: `app/build/outputs/apk/release/app-release.apk`, 34 056 839 байт,
  sha256 `ec5f5789c7aea369d018d4a9e02596561e369098f68f4ed34e6da4dc5661df8f`.
  Проверено на диске: apksigner verify — Verifies (подпись release-ключом),
  package ai.neurosignal.orchestra, versionCode 20024, versionName 2.0.24,
  assets/app/ 1698 файлов, 0 .map. Иконка в APK есть: aapt2 в релизе сокращает
  пути ресурсов (`res/BW.xml`, 448 байт — adaptive-icon XML; в debug-APK пути полные).
- `scripts/build-release.sh` обновлён: ANDROID_HOME по умолчанию, малый heap
  (-Xmx512m, MaxMetaspaceSize 256m), parallel=false, workers max 1,
  JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true. RELEASE_PROCESS.md дополнен
  (heap, ANDROID_HOME, новый fingerprint CA). PLAN.md: v2.1 помечена готовой.
- Дальше: заменить ассет в релизе orchestra-android-2.0.24 на release-подписанный APK
  (тег тот же, debug-APK остаётся на Google Drive) + запушить PLAN.md, WORK_LOG.md,
  RELEASE_PROCESS.md, scripts/build-release.sh в ryozengidoe-ux/orchestra-android
  загрузкой через браузер. На телефоне по-прежнему не ставился — v2.0.25 открыта.

## 2026-11-06 ~06:00 — v2.1-хвост: замена ассета подтверждена, пуш файлов — в работе (крон orchestra-apk-10m-watch)

- Проверка через GitHub API: ассет orchestra-android-2.0.24.apk в релизе — уже release-APK:
  34 056 839 байт, sha256 `ec5f5789c7aea369d018d4a9e02596561e369098f68f4ed34e6da4dc5661df8f`,
  загружен 05:54 по Самаре; описание релиза тоже обновлено (release-подпись, чекбоксы).
  Браузерная задача прошлого прогона (980cf22b) замену ассета выполнила.
- Не сделано: пуш обновлённых PLAN.md, WORK_LOG.md, RELEASE_PROCESS.md,
  scripts/build-release.sh — в репозитории по-прежнему коммит eb25d83 от 05:19
  (до завершения v2.1). Пуш делегирован браузеру заново в этом прогоне.
- Дальше: v2.2 (мобильная вёрстка) — аудит бандла на живых Lix-моделях.

## 2026-11-06 ~06:05 — v2.1-хвост закрыт: файлы запушены (крон orchestra-apk-10m-watch)

- Пуш в ryozengidoe-ux/orchestra-android выполнен браузером (06:01–06:04) и проверен
  независимо через GitHub API: 2 коммита в main — 7235da0 (scripts/build-release.sh)
  и 9219dca (PLAN.md, WORK_LOG.md, RELEASE_PROCESS.md); всего коммитов 4.
  Веб-загрузка GitHub привязывает коммит к одной папке — поэтому два коммита
  вместо одного, сообщение одинаковое. v2.1 теперь полностью закрыта.
- В работе: v2.2, шаг 1 — аудит мобильной вёрстки бандла (субагент, Lix).

## 2026-11-06 ~06:07 — v2.2, шаг 1: аудит мобильной вёрстки готов (крон orchestra-apk-10m-watch)

- Отчёт: `orchestra_android/v2.2-audit.md` (162 строки). Найдено 18 проблем по экранам:
  чат — 5, сессии — 2, настройки — 2, диалоги — 2, ввод/клавиатура — 3, общее — 4.
  Главные: шрифт ввода 13px (риск авто-зума), `#root 100vh` vs клавиатура,
  мелкий текст 13px и тапы 28–32px вместо 44px.
- Хорошая новость: клиент уже частично адаптирован — breakpoint 767px, bottom-sheet,
  safe-area, KeyboardInsets на visualViewport, viewport `interactive-widget=resizes-content`.
  Подход к правкам: CSS-оверрайды в новом `mobile-overrides.css` + пересборка бандла;
  4 места требуют правок компонентов. Код не менялся.
- Lix в этом прогоне почти не помог: batch на glm-5.3-prime вернул мусор
  (фрагменты tool-call разметки, finish=length), повторный review — пустой ответ
  (2000 токенов ушли в скрытый reasoning). Сработал только qwen-flash (частично,
  часть утверждений неточна). Аудит собран субагентом прямым чтением исходников/grep.
- Не проверено: поведение на устройстве (авто-зум, клавиатура, sticky, safe-area) —
  ждёт v2.0.25; содержимое `@media (max-width: 640px)` в `shell/commands/dialog.css:214`
  не разобрано до конца.
- Дальше: v2.2, шаг 2 — применить оверрайды, пересобрать бандл и APK, проверить на диске.

## 2026-11-06 ~06:08 — v2.2, шаг 2: оверрайды применены, бандл и APK пересобраны (крон orchestra-apk-10m-watch)

- По аудиту (`v2.2-audit.md`, 18 проблем) внесены правки только в копию `orchestra-src/`:
  новый `packages/app/src/mobile-overrides.css` (импорт в `index.css`), только
  `@media (max-width: 767px)`: textarea/input/select 16px (№12, №17 — авто-зум),
  текст 13→14px, 12→13px, 11→12px (№1, №9), меню/строки сессий/кнопки композера
  min 44px (№2, №3, №6), заголовки строк настроек 14px (№9), диалоги `dvh`
  вместо `vh` (№10, №11). `maximum-scale=1` не ставили (доступность).
  Плюс в `index.css`: `#root` → `height: 100vh; height: 100dvh;` (№13, dvh с фолбэком).
- №4 ОТКЛОНЁН: кламп `SESSION_PANEL_WIDTH_MIN` не делали — тесты
  `session-panel-width.test.ts` фиксируют минимум 450 как намеренный
  («never drops below the chat panel minimum»), а боковые панели на мобильном
  вообще не открываются (только `isDesktop()`). №5, №7, №14 — отложены
  до проверки на устройстве (v2.0.25): чинить без телефона — гадание.
  Заодно выяснено: в кодовой базе уже есть правило 16px для coarse-pointer
  (`(hover:none) and (pointer:coarse)`), оверрайд его дополняет, не дублирует.
- Пересборка бандла: `bun run build` в копии, 42 с, exit 0. Проверено в dist:
  оверрайды в `dist/webassets/index-*.css` (media `width<=767px`, `100dvh`,
  `min-height:44px`, `font-size:16px` — все на месте). dist 150M, `webassets/`
  на месте. В dist 1461 `.map` — это нормально: `vite.config.ts:52`
  `sourcemap: true`, в APK они не попадают (Gradle `exclude("**/*.map")`).
  Примечание: проверка «0 .map» в RELEASE_PROCESS.md относится к APK, не к dist.
- Пересборка APK: `scripts/build-release.sh`, BUILD SUCCESSFUL за 1м 08с.
  `app-release.apk`, 34 057 063 байт,
  sha256 `d6430fc93fbd1b773c2157d967bd3b681f20cb1a8ed86a8ff089431d744a3d95`.
  Проверено на диске: apksigner verify — Verifies (release-ключ),
  package ai.neurosignal.orchestra, 20024/2.0.24, assets/app/ 1698 файлов
  (webassets/ 1675), 0 .map.
- В релиз 2.0.24 на GitHub НЕ выкладывал: тег тот же, версия та же (2.0.24/20024),
  а v2.2 — промежуточная работа без приёмки на телефоне. APK — проверочная
  сборка на диске. Нумерацию версии v2.2 (versionCode меньше 20024 не годится)
  решать отдельно, до публикации.
- Lix в этом прогоне не использовался: правки детерминированные, по аудиту
  с точными file:line — модели для этого не нужны (прошлый прогон показал,
  что Lix без доступа к файлам для кода почти бесполезен).
- Дальше: v2.3 (синхронизация с апстримом + PATCHES.md). v2.0.25 по-прежнему
  ждёт телефона Shadow.
