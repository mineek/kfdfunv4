function replaceByte() {
    printf "\x00\x00\x00\x00" | dd of="$1" bs=1 seek=$2 count=4 conv=notrunc &> /dev/null
}
replaceByte 'launchd' 8 
insert_dylib @loader_path/launchdhook.dylib launchd launchdinjected --all-yes
ldid -Sentitlements.plist launchdinjected
ct_bypass -i launchdinjected -r -o launchdmineek