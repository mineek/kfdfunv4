make
insert_dylib /var/jb/springboardhook.dylib .theos/obj/debug/arm64/springboardshim SpringBoardMineek.unsigned --all-yes
ldid -SSpringBoardEnts.plist SpringBoardMineek.unsigned
ct_bypass -i SpringBoardMineek.unsigned -r -o SpringBoardMineek