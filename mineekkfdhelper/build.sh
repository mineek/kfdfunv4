if [ "$1" == "local" ]; then
    LOCAL=1 make
else
    make
fi
ldid -Sentitlements.plist .theos/obj/debug/mineekkfdhelper
ct_bypass -i .theos/obj/debug/mineekkfdhelper -r -o mineekkfdhelper