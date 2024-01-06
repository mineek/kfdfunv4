TARGET := iphone:clang:16.4:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = SpringBoardShim

SpringBoardShim_FILES = main.c
SpringBoardShim_CFLAGS = -fobjc-arc -isystem
SpringBoardShim_LDFLAGS = -L./ -lbsm
SpringBoardShim_CODESIGN_FLAGS = -SSpringBoardEnts.plist

after-package::
	ct_bypass -i .theos/obj/debug/SpringBoardShim -o SpringBoardShimsigned
	
include $(THEOS_MAKE_PATH)/tool.mk