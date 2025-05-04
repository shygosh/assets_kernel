#!/bin/bash

JOBS=$(($(nproc) / 1))
DATE="$(date '+%m%d%H%M')"
[ ! -f ../kbuild_ticket ] && echo "$DATE" > ../kbuild_ticket
[ $TC_PATH ] && export PATH="$(realpath $TC_PATH)/bin:$PATH"
INSTALL_HDR_PATH="/usr/lib/modules"

ARCH=x86
DEFCONFIG="spectre_defconfig"
O="$(realpath ../kbuild_output)"
O="${O}_$(cat ../kbuild_ticket)"
BUILD_FLAGS=(
    LLVM=1
    LLVM_IAS=1
    ARCH=$ARCH
    O=$O
)

if   [ "$1" == "r" ]; then
    make "${BUILD_FLAGS[@]}" $DEFCONFIG
    cp $O/.config arch/$ARCH/configs/$DEFCONFIG
    git status arch/$ARCH/configs/$DEFCONFIG
elif [ "$1" == "i" ]; then
    sudo make "${BUILD_FLAGS[@]}" install
elif [ "$1" == "m" ]; then
    sudo make -j $(nproc) "${BUILD_FLAGS[@]}" modules_install
elif [ "$1" == "h" ]; then
    LOCALVERSION=$(make "${BUILD_FLAGS[@]}" -s kernelrelease)
    sudo make "${BUILD_FLAGS[@]}" headers_install INSTALL_HDR_PATH=$INSTALL_HDR_PATH/$LOCALVERSION
elif [ "$1" == "t" ]; then
    rm -f ../kbuild_ticket
elif [ "$1" == "c" ]; then
    rm -rf $O
elif [ "$1" == "p" ]; then
    echo "kver: $(make "${BUILD_FLAGS[@]}" -s kernelrelease)"
    echo "path: $(realpath $O/arch/$ARCH/boot/*Image*)"
elif [ "$1" == "" ]; then
    SECONDS=0
    make "${BUILD_FLAGS[@]}" $DEFCONFIG
    echo -e "\nDate: $DATE\n" >> ../kbuild_log_${ARCH}_$(cat ../kbuild_ticket)
    make -j $JOBS "${BUILD_FLAGS[@]}" 2>&1 | tee -a ../kbuild_log_${ARCH}_$(cat ../kbuild_ticket)
    echo -e "\nElapsed Time: $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)\n"
else
    echo "Unknown argument!"
    exit 1
fi
