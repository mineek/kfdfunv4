make
insert_dylib @loader_path/springboardhook.dylib .theos/obj/debug/arm64e/springboardshim SpringBoardMineek.unsigned --all-yes
ldid -SSpringBoardEnts.plist SpringBoardMineek.unsigned
ct_bypass -i SpringBoardMineek.unsigned -r -o SpringBoardMineek