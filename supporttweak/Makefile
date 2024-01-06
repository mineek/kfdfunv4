TARGET := iphone:clang:16.4:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = supporttweak

supporttweak_FILES = Tweak.x
supporttweak_CFLAGS = -fobjc-arc

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -r -o launchdhook.dylib

include $(THEOS_MAKE_PATH)/tweak.mk
