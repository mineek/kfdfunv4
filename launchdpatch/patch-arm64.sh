insert_dylib @loader_path/launchdhook.dylib launchd launchdinjected --all-yes
ldid -Sentitlements.plist launchdinjected
ct_bypass -i launchdinjected -r -o launchdmineek