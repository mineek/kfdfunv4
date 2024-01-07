TARGET := iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = kfdmineek
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = kfdmineek

kfdmineek_FILES = $(wildcard *.m) $(wildcard ../shared/*.m)
kfdmineek_FRAMEWORKS = UIKit CoreGraphics IOKit Foundation CoreTelephony
kfdmineek_CFLAGS = -fobjc-arc -Wno-error -I../exploit -I../include -I../shared
ifeq ($(MANUAL_EXPLOIT_METHOD),1)
	kfdmineek_CFLAGS += -DUSE_MANUAL_EXPLOIT_METHOD
endif
kfdmineek_CODESIGN_FLAGS = -Sentitlements.plist
kfdmineek_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileContainerManager FrontBoardServices

include $(THEOS_MAKE_PATH)/application.mk

after-package::
	@echo "Removing old files (if any)..."
	@rm -rf $(THEOS_OBJ_DIR)/Payload || true
	@rm -rf $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).ipa || true
	@rm -rf $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).tipa || true
	@rm -rf $(THEOS_PACKAGE_DIR)/$(APPLICATION_NAME).tipa || true
	@echo "Making .tipa..."
	@mkdir -p $(THEOS_OBJ_DIR)/Payload
	@mv $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app
	@cp $(THEOS_PACKAGE_DIR)/../../mineekkfdhelper/mineekkfdhelper $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/mineekkfdhelper
	@cp $(THEOS_PACKAGE_DIR)/../bins/ct_bypass $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/ct_bypass
	@cp $(THEOS_PACKAGE_DIR)/../../tools/insert_dylib $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/insert_dylib
	@if [ "$(LOCAL)" = "1" ]; then \
		cp $(THEOS_PACKAGE_DIR)/../../launchdhook/launchdhook.dylib $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/launchdhook.dylib; \
		cp $(THEOS_PACKAGE_DIR)/../../springboardshim/SpringBoardMineek $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/SpringBoardMineek; \
		cp $(THEOS_PACKAGE_DIR)/../../supporttweak/springboardhook.dylib $(THEOS_OBJ_DIR)/Payload/$(APPLICATION_NAME).app/springboardhook.dylib; \
	fi
	@cd $(THEOS_OBJ_DIR) && zip -r $(APPLICATION_NAME).ipa Payload
	@mv $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).ipa $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).tipa
	@mv $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).tipa $(THEOS_PACKAGE_DIR)
	@echo "Done, .tipa is at $(THEOS_PACKAGE_DIR)/$(APPLICATION_NAME).tipa"
