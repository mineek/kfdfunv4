current_dir=$(pwd)
folders=("mineekkfdhelper" "launchdhook" "springboardshim" "supporttweak")
local_mode=1 # 0 for remote, 1 for local
for folder in "${folders[@]}"; do
    cd $current_dir/../$folder
    echo "Making $folder..."
    if [ $local_mode -eq 1 ] && [ $folder == "mineekkfdhelper" ]; then
        ./build.sh local
    else
        ./build.sh
    fi
    cd $current_dir
done
if [ $local_mode -eq 1 ]; then
    LOCAL=1 make package
else
    make package
fi