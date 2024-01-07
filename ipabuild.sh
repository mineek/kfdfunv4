#!/bin/bash

set -e

cd "$(dirname "$0")"

WORKING_LOCATION="$(pwd)"

current_dir=$(pwd)
folders=("mineekkfdhelper" "launchdhook" "springboardshim" "supporttweak")
local_mode=1 # 0 for remote, 1 for local

# Build basebin
for folder in "${folders[@]}"; do
    cd $current_dir/$folder
    echo "Making $folder..."
    if [ $local_mode -eq 1 ] && [ $folder == "mineekkfdhelper" ]; then
        ./build.sh local
    else
        ./build.sh
    fi
    cd $current_dir
done

APPLICATION_NAME=kfdfun
CONFIGURATION=$1
if [ -z "$CONFIGURATION" ]; then
    CONFIGURATION=Release
fi

rm -rf build
mkdir build

cd build
if [ -e "$APPLICATION_NAME.ipa" ]; then
rm $APPLICATION_NAME.ipa
fi

echo "Building $APPLICATION_NAME"
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \

DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/$CONFIGURATION-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

echo "Stripping $APPLICATION_NAME"
strip "$TARGET_APP/$APPLICATION_NAME"

# Remove signature
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# Entitlements
ldid -S"$WORKING_LOCATION/entitlements.plist" "$TARGET_APP/$APPLICATION_NAME"

# Copy basebin
cp "$WORKING_LOCATION"/mineekkfdhelper/mineekkfdhelper "$TARGET_APP/mineekkfdhelper"
if [ $local_mode -eq 1 ]; then
    cp "$WORKING_LOCATION"/launchdhook/launchdhook.dylib "$TARGET_APP/launchdhook.dylib"
    cp "$WORKING_LOCATION"/springboardshim/SpringBoardMineek "$TARGET_APP/SpringBoardMineek"
    cp "$WORKING_LOCATION"/supporttweak/springboardhook.dylib "$TARGET_APP/springboardhook.dylib"
fi

# Package .ipa
echo "Packaging $APPLICATION_NAME.ipa"
cd "$WORKING_LOCATION/build"
rm -rf Payload
mkdir Payload
cp -r "$APPLICATION_NAME.app" Payload/
zip -vr "$APPLICATION_NAME.ipa" Payload/
rm -rf Payload

echo "Done, output is at $WORKING_LOCATION/build/$APPLICATION_NAME.ipa"
