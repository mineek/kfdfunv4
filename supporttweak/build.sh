make
ldid -S../launchdhook/entitlements.plist -Cadhoc .theos/obj/debug/supporttweak.dylib
install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate @loader_path/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate .theos/obj/debug/supporttweak.dylib
ct_bypass -i .theos/obj/debug/supporttweak.dylib -r -o springboardhook.dylib