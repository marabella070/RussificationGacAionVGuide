#!/usr/bin/env bash
# Установка APK/app-bundle из подпапок. Работает в git bash, Linux, macOS.

# Запрещает использовать неинициализированные переменные:
#   если обратиться к $FOO, которой нет, скрипт упадёт 
#   с ошибкой, а не подставит пустую строку
set -u

# $0 — специальная переменная, содержащая путь самого запущенного скрипта
# dirname — утилита, которая отрезает имя файла и оставляет только путь к его родительской директории
# если перейти в родительский каталог не удалось -> выполняется exit 1
cd "$(dirname "$0")" || exit 1


# --- проверки ---

# comand -v adb - сообщает местонахождение adb, если оно конечно есть)
# вывод(stdout) перенаправляется в пустоту(/dev/null)
# 2>&1, поток ошибок(stderr), так же как stdout перенаправляется в пустоту
# Таким образом если adb не была найдена, условие верно
if ! command -v adb >/dev/null 2>&1; then
    echo "ОШИБКА: adb не найден в PATH." >&2
    exit 1
fi


# adb devices - выводит список устройств:
#   List of devices attached
#   emulator-5554	device
#   R58M12ABCDE	unauthorized
# awk построчно обрабатывает вход
#   NR(Number of Record) - обрабатывает все строки кроме 1
#   $1 и $2 - первое и второе поле строки соотв.
#   {print $1} - для строк, прошедших условие, напечатать первое поле(серийный номер)
DEVICES=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')


COUNT=$(printf '%s\n' "$DEVICES" | grep -c . || true)


if [ "$COUNT" -eq 0 ]; then
    echo "ОШИБКА: нет подключённых устройств (adb devices)." >&2
    adb devices
    exit 1
elif [ "$COUNT" -gt 1 ]; then
    echo "Подключено несколько устройств:"
    printf '  %s\n' $DEVICES
    echo "Оставьте одно или задайте ANDROID_SERIAL=<serial> и перезапустите."
    exit 1
fi

echo "Устройство: $DEVICES"
echo

# --- обход подпапок ---
shopt -s nullglob 2>/dev/null || true
found_any=0

for dir in */ ; do
    dir="${dir%/}"
    [ "$dir" = "." ] && continue

    # собираем apk в папке (без вложенных подпапок)
    apks=()
    while IFS= read -r -d '' f; do
        apks+=("$f")
    done < <(find "$dir" -maxdepth 1 -type f -iname '*.apk' -print0)

    n=${#apks[@]}
    if [ "$n" -eq 0 ]; then
        continue
    fi
    found_any=1

    echo "==> [$dir] найдено APK: $n"
    for a in "${apks[@]}"; do echo "      $(basename "$a")"; done

    if [ "$n" -eq 1 ]; then
        echo "    режим: одиночный APK (adb install)"
        adb install -r "${apks[0]}"
    else
        echo "    режим: app-bundle (adb install-multiple)"
        # передаём все apk; система сама выберет подходящие сплиты
        adb install-multiple -r "${apks[@]}"
    fi

    rc=$?
    if [ $rc -eq 0 ]; then
        echo "    OK"
    else
        echo "    ОШИБКА (код $rc)" >&2
    fi
    echo
done

if [ "$found_any" -eq 0 ]; then
    echo "В подпапках не найдено ни одного .apk"
fi
