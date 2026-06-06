#!/bin/bash
# Сборка релизных артефактов 1С (.cf / .cfe) и публикация в GitHub Releases.
#
# Платформа 1С нужна локально (на GitHub-раннерах её нет) — скрипт запускается
# с машины разработчика. Путь к платформе берётся из .v8-project.json (v8path).
#
# Usage:
#   bash scripts/build-release.sh <tag> [--no-publish]
#   например: bash scripts/build-release.sh v0.1.0
#
# Артефакты:
#   - kabitoriy.cf   из 1c/standalone/src              (standalone-форма)
#   - kabitoriy.cfe  из 1c/extension/src (если есть)   (extension-форма)
#   - SHA256SUMS.txt
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

TAG="${1:?Укажите тег, напр.: bash scripts/build-release.sh v0.1.0}"
PUBLISH=1
[ "${2:-}" = "--no-publish" ] && PUBLISH=0

V8=$(python3 -c "import json;print(json.load(open('.v8-project.json'))['v8path'])")
test -x "$V8" || { echo "Нет платформы 1С: $V8"; exit 1; }

OUT="$ROOT/base/release"; rm -rf "$OUT"; mkdir -p "$OUT"
BUILDIB="$ROOT/base/build-ib"
LOG="$ROOT/base/build.log"

guard() { perl -e 'alarm 300; exec @ARGV' "$@"; }

# build_artifact <src-dir> <out-file> [extension-name]
build_artifact() {
	local SRC="$1" OUTF="$2" EXT="${3:-}"
	rm -rf "$BUILDIB"; mkdir -p "$BUILDIB"
	guard "$V8" CREATEINFOBASE File="$BUILDIB" /DisableStartupDialogs >/dev/null
	if [ -z "$EXT" ]; then
		guard "$V8" DESIGNER /F"$BUILDIB" /LoadConfigFromFiles "$SRC" /UpdateDBCfg /DisableStartupDialogs /Out "$LOG" >/dev/null
		guard "$V8" DESIGNER /F"$BUILDIB" /DumpCfg "$OUTF" /DisableStartupDialogs /Out "$LOG" >/dev/null
	else
		guard "$V8" DESIGNER /F"$BUILDIB" /LoadConfigFromFiles "$SRC" -Extension "$EXT" /UpdateDBCfg /DisableStartupDialogs /Out "$LOG" >/dev/null
		guard "$V8" DESIGNER /F"$BUILDIB" /DumpCfg "$OUTF" -Extension "$EXT" /DisableStartupDialogs /Out "$LOG" >/dev/null
	fi
	test -f "$OUTF" || { echo "Не собран: $OUTF"; cat "$LOG"; exit 1; }
}

echo "[build] kabitoriy.cf (standalone)"
build_artifact "$ROOT/1c/standalone/src" "$OUT/kabitoriy.cf"

CFE_LINE=""
if [ -f "$ROOT/1c/extension/src/Configuration.xml" ]; then
	EXTNAME=$(python3 -c "import re;print(re.search(r'<Name>([^<]+)</Name>',open('1c/extension/src/Configuration.xml',encoding='utf-8').read()).group(1))")
	echo "[build] kabitoriy.cfe (extension: $EXTNAME)"
	build_artifact "$ROOT/1c/extension/src" "$OUT/kabitoriy.cfe" "$EXTNAME"
	CFE_LINE="- kabitoriy.cfe — расширение (extension-форма)"
else
	echo "[skip] 1c/extension/src пуст — .cfe не собираем"
fi

rm -rf "$BUILDIB"
echo "[checksums]"
( cd "$OUT" && shasum -a 256 * > SHA256SUMS.txt )
ls -lh "$OUT"

if [ "$PUBLISH" = "1" ]; then
	echo "[release] gh release create $TAG"
	NOTES="Артефакты сборки Кабитория (1С), собраны из исходников (выгрузка конфигуратора в XML).

- kabitoriy.cf — конфигурация (standalone-форма)
$CFE_LINE

Совместимость платформы: 8.3.24+. Контрольные суммы — в SHA256SUMS.txt."
	gh release create "$TAG" "$OUT"/* --title "Кабиторий $TAG" --notes "$NOTES" --prerelease
	echo "[ok] релиз $TAG опубликован"
else
	echo "[no-publish] артефакты в $OUT"
fi
