#!/usr/bin/env bash
# Release-сборка Orchestra Android: подписанный APK.
# Использование: scripts/build-release.sh [versionCode]
#   versionCode не задан — Gradle вычислит его из версии бандла (2.0.24 -> 20024).
# Пароли keystore — только из release/keystore-passwords.env (chmod 600, в git не попадает),
# в репозитории и в логах паролей нет. Подробности — в RELEASE_PROCESS.md.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

ENV_FILE="$PROJECT_DIR/release/keystore-passwords.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Нет $ENV_FILE — сначала создайте keystore (см. RELEASE_PROCESS.md)" >&2
  exit 1
fi
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a
export ORCHESTRA_ANDROID_KEYSTORE="$PROJECT_DIR/release/orchestra-release.keystore"
[[ -f "$ORCHESTRA_ANDROID_KEYSTORE" ]] || { echo "Нет keystore: $ORCHESTRA_ANDROID_KEYSTORE" >&2; exit 1; }

export JAVA_HOME="$HOME/workspace/.jdk21/jdk-21.0.13+9"
export PATH="$JAVA_HOME/bin:$PATH"
export GRADLE_USER_HOME=/home/hatch/.gradle
export ANDROID_HOME="${ANDROID_HOME:-/home/hatch/android-sdk}"
export JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true

GRADLE="$HOME/.gradle/wrapper/dists/gradle-9.6.0-bin/gradle-9.6.0/bin/gradle"
[[ -x "$GRADLE" ]] || { echo "Нет Gradle 9.6.0: $GRADLE" >&2; exit 1; }

# Малый heap: в песочнице ~700 МБ свободно, -Xmx1g из gradle.properties не лезет.
# -Dorg.gradle.jvmargs на командной строке перебивает gradle.properties.
ARGS=(--no-daemon
  "-Dorg.gradle.jvmargs=-Xmx512m -XX:MaxMetaspaceSize=256m -Djavax.net.ssl.trustStore=$PROJECT_DIR/gradle/hatch-cacerts -Djavax.net.ssl.trustStorePassword=changeit -Dfile.encoding=UTF-8"
  -Dorg.gradle.parallel=false -Dorg.gradle.workers.max=1
  "-PwebBundleDir=$HOME/workspace/orchestra-src/packages/app/dist"
  -x :app:buildWebApp)
if [[ $# -ge 1 ]]; then ARGS+=("-PversionCode=$1"); fi
ARGS+=(assembleRelease)

"$GRADLE" "${ARGS[@]}"

APK="$PROJECT_DIR/app/build/outputs/apk/release/app-release.apk"
[[ -f "$APK" ]] || { echo "APK не собран: $APK" >&2; exit 1; }
ls -l "$APK"
sha256sum "$APK"
