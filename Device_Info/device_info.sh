# Версия Android
adb shell getprop ro.build.version.release      # 13, 14, ...
adb shell getprop ro.build.version.sdk          # 33, 34, ... (API level)

# ABI (архитектура) — главное поле abilist, оно упорядочено по приоритету
adb shell getprop ro.product.cpu.abilist        # arm64-v8a,armeabi-v7a,armeabi
adb shell getprop ro.product.cpu.abi            # основной (первый)

# Плотность экрана
adb shell wm density                            # Physical density: 420
adb shell getprop ro.sf.lcd_density             # иногда есть, иногда нет