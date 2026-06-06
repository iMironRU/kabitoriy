#!/bin/bash
# Прогон YAxUnit-тестов ядра Кабитория на файловой dev-ИБ (headless, macOS).
# Полный идемпотентный флоу: грузит главную конфу + расширения, снимает
# безопасный режим, запускает тесты, печатает разбор jUnit-отчёта.
#
# Требования (один раз):
#   - Платформа 1С (путь берётся из .v8-project.json -> v8path)
#   - tools/yaxunit/YAxUnit.cfe  (скачать с github.com/bia-technologies/yaxunit/releases)
#   - tools/yaxunit/DisableSafeMode.epf
#
# Запуск:  bash tools/run-tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

V8=$(python3 -c "import json;print(json.load(open('.v8-project.json'))['v8path'])")
IB="$ROOT/base/ib_dev"
SRC="$ROOT/1c/standalone/src"
TSRC="$ROOT/1c/standalone/tests/src"
YAX="$ROOT/tools/yaxunit/YAxUnit.cfe"
DSM="$ROOT/tools/yaxunit/DisableSafeMode.epf"
LOG="$ROOT/base/test-run.log"

test -x "$V8" || { echo "Нет бинаря платформы: $V8"; exit 1; }
test -f "$YAX" || { echo "Нет $YAX (скачать YAxUnit cfe)"; exit 1; }

guard() { perl -e 'alarm 240; exec @ARGV' "$@"; }

# Свежая ИБ на каждый прогон — изоляция тестовых данных между запусками
rm -rf "$IB"; mkdir -p "$IB"
guard "$V8" CREATEINFOBASE File="$IB" /DisableStartupDialogs >/dev/null

echo "[1/5] главная конфигурация";  guard "$V8" DESIGNER /F"$IB" /LoadConfigFromFiles "$SRC" /UpdateDBCfg /DisableStartupDialogs /Out "$LOG" >/dev/null
echo "[2/5] расширение YAxUnit";     guard "$V8" DESIGNER /F"$IB" /LoadCfg "$YAX" -Extension YAxUnit /UpdateDBCfg /DisableStartupDialogs /Out "$LOG" >/dev/null
echo "[3/5] расширение tests";       guard "$V8" DESIGNER /F"$IB" /LoadConfigFromFiles "$TSRC" -Extension tests /UpdateDBCfg /DisableStartupDialogs /Out "$LOG" >/dev/null

echo "[4/5] снятие безопасного режима"
mkdir -p ~/.1cv8/1C/1cv8/conf/
grep -q "DisableUnsafeActionProtection" ~/.1cv8/1C/1cv8/conf/conf.cfg 2>/dev/null \
  || echo "DisableUnsafeActionProtection=.*" >> ~/.1cv8/1C/1cv8/conf/conf.cfg
guard "$V8" ENTERPRISE /F"$IB" /Execute "$DSM" /DisableStartupDialogs /DisableStartupMessages /Out "$LOG" >/dev/null

echo "[5/5] прогон тестов"
RP="$ROOT/base/yax-report.xml"; EX="$ROOT/base/yax-exit.txt"
rm -f "$RP" "$EX"
cat > "$ROOT/base/yax-config.json" <<JSON
{ "reportFormat": "jUnit", "reportPath": "$RP", "closeAfterTests": true,
  "showReport": false, "exitCode": "$EX",
  "filter": { "extensions": ["tests"] },
  "logging": { "console": false, "file": "$ROOT/base/yax.log", "level": "info" } }
JSON
guard "$V8" ENTERPRISE /F"$IB" /DisableSplash /DisableStartupDialogs /DisableStartupMessages \
  /RunModeManagedApplication /C "RunUnitTests=$ROOT/base/yax-config.json" >/dev/null || true

python3 - "$RP" <<'PY'
import sys, xml.etree.ElementTree as ET
r = ET.parse(sys.argv[1]).getroot()
tot=f=e=sk=0
for s in r.findall(".//testsuite"):
    tot+=int(s.get("tests",0)); f+=int(s.get("failures",0)); e+=int(s.get("errors",0)); sk+=int(s.get("skipped",0) or 0)
    print(f"\nНабор {s.get('name')}: tests={s.get('tests')} failures={s.get('failures')} errors={s.get('errors')}")
    for tc in s.findall("testcase"):
        bad = tc.find("failure") if tc.find("failure") is not None else tc.find("error")
        print(("   FAIL " if bad is not None else "   OK   ")+tc.get("name"))
        if bad is not None:
            print("        ->", (bad.get("message") or bad.text or "").strip()[:200])
print(f"\nИТОГО {tot}: OK={tot-f-e-sk} FAIL={f} ERROR={e} SKIP={sk}")
sys.exit(1 if (f or e) else 0)
PY
