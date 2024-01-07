TARGET := iphone:clang:16.4:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook

launchdhook_FILES = $(wildcard *.m) $(wildcard *.c) $(wildcard verbose/*.m)
launchdhook_CFLAGS = -fobjc-arc -I../include -Wno-error
launchdhook_CODESIGN_FLAGS = -Sentitlements.plist
launchdhook_EXTRA_FRAMEWORKS += IOMobileFramebuffer
launchdhook_LDFLAGS = -F./Frameworks

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -r -o launchdhook.dylib
include $(THEOS_MAKE_PATH)/library.mk