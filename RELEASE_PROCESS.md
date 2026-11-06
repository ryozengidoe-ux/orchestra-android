# Процесс релиза — Orchestra Android

Пакет `ai.neurosignal.orchestra`. Проект: `/home/hatch/workspace/orchestra_android`.
Бандл — из рабочей копии `/home/hatch/workspace/orchestra-src/packages/app/dist`
(оригинал NeiP4n — только read-only референс, не трогать).
Локальная папка проекта — НЕ git-репозиторий: коммиты и релизы делаются
загрузкой через браузер в `ryozengidoe-ux/orchestra-android`.
`version.json` и репозитории Lumus-ai не трогать.

## 1. Пересборка бандла

```bash
cd /home/hatch/workspace/orchestra-src
bun install
cd packages/app
VITE_ORCHESTRA_SERVER_MODE=none ORCHESTRA_CHANNEL=beta bun run build
```

Проверка бандла:

```bash
ls dist/index.html            # должен быть
ls -d dist/webassets          # НЕ _assets — AGP молча отбрасывает папки на _
find dist -name '*.map' | wc -l   # должно быть 0
du -sh dist/                  # ~150M
```

## 2. Release-keystore

Один раз (уже создан 06.11.2026):

```bash
cd /home/hatch/workspace/orchestra_android
# пароль — случайный, в файл release/keystore-passwords.env (chmod 600)
keytool -genkeypair -keystore release/orchestra-release.keystore \
  -alias orchestra-release -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PW" -keypass "$PW" -dname "CN=Orchestra Android, O=Neurosignal"
```

- Keystore: `release/orchestra-release.keystore` (SHA-256 `A7:46:B1:DA:EB:C3:15:E3:F6:14:3C:F9:B9:FE:E7:F8:8A:5A:57:05:35:54:3C:56:1B:68:7C:23:43:87:6F:60`).
- Пароли — только в `release/keystore-passwords.env`, в репозиторий не попадают
  (папка `release/` — в `.gitignore`). Пароль нигде не печатать и не пересылать.
- Потеря keystore = новый ключ = пользователи не смогут обновиться поверх старого APK.

## 3. Сборка релизного APK

Готовый скрипт (делает всё ниже сам):

```bash
scripts/build-release.sh [versionCode]
```

Вручную — то же самое:

```bash
cd /home/hatch/workspace/orchestra_android
export JAVA_HOME="$HOME/workspace/.jdk21/jdk-21.0.13+9"
export PATH="$JAVA_HOME/bin:$PATH"
export GRADLE_USER_HOME=/home/hatch/.gradle
set -a; source release/keystore-passwords.env; set +a
export ORCHESTRA_ANDROID_KEYSTORE="$PWD/release/orchestra-release.keystore"
~/.gradle/wrapper/dists/gradle-9.6.0-bin/gradle-9.6.0/bin/gradle --no-daemon \
  -PwebBundleDir=/home/hatch/workspace/orchestra-src/packages/app/dist \
  -PversionCode=N -x :app:buildWebApp assembleRelease
```

Замечания:

- Gradle — только распакованный 9.6.0 напрямую (`gradlew` каждый раз пытается скачать
  дистрибутив и падает на TLS). `--no-daemon`, `GRADLE_USER_HOME=/home/hatch/.gradle`.
- **Heap: только `-Xmx512m`** (проверено 06.11.2026 ~05:49): в песочнице ~700 МБ свободно,
  `-Xmx1g` из gradle.properties не лезет — сборка падает по RAM. Перебивается флагом
  `-Dorg.gradle.jvmargs="-Xmx512m -XX:MaxMetaspaceSize=256m ..."` на командной строке
  (уже вшит в `scripts/build-release.sh`). `org.gradle.parallel=false`, workers max 1.
- **ANDROID_HOME обязателен**: `export ANDROID_HOME=/home/hatch/android-sdk` — в env
  песочницы не задан, без него Gradle: «SDK location not found». Тоже вшит в скрипт.
- trustStore уже прописан в `gradle.properties`. CA ротируется: при ошибке
  `PKIX path building failed` пересобрать trustStore из текущего
  `/run/hatch/egress-tls/ca-bundle.pem` (найти «Hatch Sandbox Egress CA»,
  `keytool -importcert` в свежую копию cacerts). **06.11.2026 ~05:50 CA снова
  ротировался: текущий fingerprint `38:B2:94:EF:BE:B3:F8:A4:02:29:7D:94:03:C5:DD:82:F8:25:90:E8:1D:FB:9C:34:80:DC:4A:5E:AB:64:01:81`
  (старый `6C:C1:D9…` мёртв) — trustStore `gradle/hatch-cacerts` пересобран.**
  Без пересборки release-сборка падает на `lintVitalAnalyzeRelease` (не может скачать
  lint-gradle 32.4.0 с dl.google.com).
- `versionCode`: +1 каждый релиз (`-PversionCode=N`). Без флага Gradle вычислит
  его из версии бандла (2.0.24 → 20024). `versionName` берётся из
  `../orchestra-app/package.json` и совпадает с версией бандла.
- Иконка: `design/orchestra-icon-opus.png` (1024×1024) уже разложена по
  `app/src/main/res/mipmap-*/` (ic_launcher, ic_launcher_round,
  ic_launcher_foreground; фон `#0E0E11` в `values/ic_launcher_background.xml`).

## 4. Проверка готового APK

```bash
APK=app/build/outputs/apk/release/app-release.apk
apksigner verify "$APK"                    # должен сказать Verifies
sha256sum "$APK"
unzip -l "$APK" | grep -c 'assets/app/'    # ~1698 файлов
aapt2 dump badging "$APK" | grep -E 'package:|versionCode|versionName'
```

Честно фиксировать, что проверено: «на диске» ≠ «на телефоне», не путать.

## 5. Публикация релиза

Коннектор GitHub даёт 403 на запись, `gh` не проверен — релиз делается
загрузкой через браузер:

1. `github.com/ryozengidoe-ux/orchestra-android/releases/new`, сессия ryozengidoe-ux.
2. Тег `orchestra-android-<version>`, цель main, пометка Latest.
3. Загрузить ассет `orchestra-android-<version>.apk` (копия готового APK).
4. Описание — по шаблону ниже.

## Шаблон release notes

```
Версия: <version>
versionCode: N
SHA256: <hash>
Размер: <size> МБ
Что изменилось:
- ...

Что проверено:
- [ ] на диске (apksigner verify, sha256, assets/app, badging)
- [ ] на телефоне (установка, первый запуск, подключение к серверу)

Ссылка на APK: https://github.com/ryozengidoe-ux/orchestra-android/releases/tag/orchestra-android-<version>
```

Отмечать только то, что реально проверено.
