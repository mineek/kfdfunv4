make
ldid -S../launchdhook/entitlements.plist -Cadhoc .theos/obj/debug/supporttweak.dylib
ct_bypass -i .theos/obj/debug/supporttweak.dylib -r -o springboardhook.dylib