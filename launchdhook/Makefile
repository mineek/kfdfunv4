TARGET := iphone:clang:16.4:14.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook

launchdhook_FILES = $(wildcard *.m) $(wildcard *.c)
launchdhook_CFLAGS = -fobjc-arc -I../include
launchdhook_CODESIGN_FLAGS = -Sentitlements.plist

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -o launchdhook.dylib
include $(THEOS_MAKE_PATH)/library.mk