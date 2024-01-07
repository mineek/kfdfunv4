TARGET := iphone:clang:14.5:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = mineekkfdhelper

mineekkfdhelper_FILES = $(wildcard *.m) $(wildcard ../shared/*.m)
mineekkfdhelper_CFLAGS = -fobjc-arc -I../shared
ifeq ($(LOCAL),1)
	mineekkfdhelper_CFLAGS += -DUSE_LOCAL_FILES
endif
mineekkfdhelper_CODESIGN_FLAGS = -Sentitlements.plist
mineekkfdhelper_INSTALL_PATH = /usr/local/bin
mineekkfdhelper_LIBRARIES = archive
mineekkfdhelper_FRAMEWORKS = CoreTelephony
mineekkfdhelper_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileContainerManager FrontBoardServices

include $(THEOS_MAKE_PATH)/tool.mk
