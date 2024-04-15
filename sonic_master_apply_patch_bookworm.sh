#!/bin/bash

# Copyright (c) Marvell, Inc. All rights reservered. Confidential.
# Description: Applying open PRs needed for compilation


#
# patch script for Intel Falcon board
#

#
# CONFIGURATIONS:-
#

SONIC_COMMIT="006f4b209c919b41a7c1ebd0afdfe07885ef4cad"

#
# END of CONFIGURATIONS
#

# PREDEFINED VALUES
CUR_DIR=$(basename `pwd`)
LOG_FILE=patches_result.log
FULL_PATH=`pwd`

# Path for master patches
WGET_PATH="https://raw.githubusercontent.com/Marvell-switching/sonic-scripts/master_04/files/master-bookworm/"

# Patches
SERIES="0001-Redis-timeout-WA.patch
	0001-Add-x86-platforms.patch
	0001-Falcon-usb-disk-hung_task-WA.patch
	18678.patch"

PATCHES=""

# Sub module patches
declare -a SUB_PATCHES=(SP1 SP2)
declare -A SP1=([NAME]="0001-SAI-switch-create-timeout-WA.patch" [DIR]="src/sonic-sairedis")
declare -A SP2=([NAME]="0001-Marvell-pfc-detect-change.patch" [DIR]="src/sonic-swss")

log()
{
    echo $@
    echo $@ >> ${FULL_PATH}/${LOG_FILE}
}

pre_patch_help()
{
    log "STEPS TO BUILD:"
    log "git clone https://github.com/sonic-net/sonic-buildimage.git"
    log "cd sonic-buildimage"
    log "git checkout $SONIC_COMMIT"
    log "make init"

    log "<<Apply patches using patch script>>"
    log "bash $0"

    log "<<FOR ARM64>> make configure PLATFORM=marvell PLATFORM_ARCH=arm64"
    log "<<FOR ARM64>> make target/sonic-marvell-arm64.bin"
    log "<<FOR INTEL>> make configure PLATFORM=marvell"
    log "<<FOR INTEL>> make target/sonic-marvell.bin"
}

apply_patch_series()
{
    for patch in $SERIES
    do
        echo $patch
        pushd patches
        wget --timeout=2 -c $WGET_PATH/$patch
        popd
        git am patches/$patch
        if [ $? -ne 0 ]; then
            log "ERROR: Failed to apply patch $patch"
            exit 1
        fi
    done
}

apply_patches()
{
    for patch in $PATCHES
    do
	echo $patch	
    	pushd patches
    	wget --timeout=2 -c $WGET_PATH/$patch
        popd
	    patch -p1 < patches/$patch
        if [ $? -ne 0 ]; then
	        log "ERROR: Failed to apply patch $patch"
            exit 1
    	fi
    done
}

apply_submodule_patches()
{
    CWD=`pwd`
    for SP in ${SUB_PATCHES[*]}
    do
	patch=${SP}[NAME]
	dir=${SP}[DIR]
	echo "${!patch}"
    	pushd patches
    	wget --timeout=2 -c $WGET_PATH/${!patch}
        popd
	    pushd ${!dir}
        git am $CWD/patches/${!patch}
        if [ $? -ne 0 ]; then
	        log "ERROR: Failed to apply patch ${!patch}"
            exit 1
    	fi
	popd
    done
}

apply_hwsku_changes()
{
    # Download hwsku
    wget --timeout=2 -c https://raw.githubusercontent.com/Marvell-switching/sonic-scripts/master_04/files/mrvl_sonic_hwsku_ezb.tgz

    rm -fr device/marvell/x86_64-marvell_db98cx8580_32cd-r0 || true
    rm -rf device/marvell/x86_64-marvell_slm5401_54x-r0     || true
    rm -fr device/marvell/arm64-marvell_db98cx8580_32cd-r0  || true
    rm -fr device/marvell/x86_64-marvell_db98cx8540_16cd-r0 || true
    rm -fr device/marvell/arm64-marvell_db98cx8540_16cd-r0  || true
    rm -fr device/marvell/armhf-marvell_et6448m_52x-r0      || true
    tar -C device/marvell/ -xzf mrvl_sonic_hwsku_ezb.tgz
    cp -dr device/marvell/arm64-marvell_db98cx8580_32cd-r0 device/marvell/x86_64-marvell_db98cx8580_32cd-r0
    cp -dr device/marvell/arm64-marvell_db98cx8540_16cd-r0 device/marvell/x86_64-marvell_db98cx8540_16cd-r0
    cp -dr device/marvell/arm64-marvell_db98cx8514_10cc-r0 device/marvell/x86_64-marvell_db98cx8514_10cc-r0
    rm device/marvell/arm64-marvell_db98cx8580_32cd-r0/plugins/x86_64_sfputil.py
    rm device/marvell/arm64-marvell_db98cx8540_16cd-r0/plugins/x86_64_sfputil.py
    rm device/marvell/arm64-marvell_db98cx8514_10cc-r0/plugins/x86_64_sfputil.py
    mv device/marvell/x86_64-marvell_db98cx8580_32cd-r0/plugins/x86_64_sfputil.py device/marvell/x86_64-marvell_db98cx8580_32cd-r0/plugins/sfputil.py
    mv device/marvell/x86_64-marvell_db98cx8540_16cd-r0/plugins/x86_64_sfputil.py device/marvell/x86_64-marvell_db98cx8540_16cd-r0/plugins/sfputil.py
    mv device/marvell/x86_64-marvell_db98cx8514_10cc-r0/plugins/x86_64_sfputil.py device/marvell/x86_64-marvell_db98cx8514_10cc-r0/plugins/sfputil.py
    echo "marvell" > device/marvell/x86_64-marvell_db98cx8514_10cc-r0/platform_asic
    echo "marvell" > device/marvell/x86_64-marvell_db98cx8540_16cd-r0/platform_asic
    echo "marvell" > device/marvell/x86_64-marvell_db98cx8580_32cd-r0/platform_asic
    echo "marvell" > device/marvell/arm64-marvell_db98cx8514_10cc-r0/platform_asic
    echo "marvell" > device/marvell/arm64-marvell_db98cx8540_16cd-r0/platform_asic
    echo "marvell" > device/marvell/arm64-marvell_db98cx8580_32cd-r0/platform_asic
    echo "marvell" > device/marvell/arm64-marvell_rd98DX35xx-r0/platform_asic
    echo "marvell" > device/marvell/arm64-marvell_rd98DX35xx_cn9131-r0/platform_asic
    echo "marvell" > device/marvell/x86_64-marvell_rd98DX35xx-r0/platform_asic
}

main()
{
    sonic_buildimage_commit=`git rev-parse HEAD`
    if [ "$CUR_DIR" != "sonic-buildimage" ]; then
        log "ERROR: Need to be at sonic-builimage git clone path"
        pre_patch_help
        exit
    fi

    if [ "${sonic_buildimage_commit}" != "$SONIC_COMMIT" ]; then
        log "Checkout sonic-buildimage commit to proceed"
        log "git checkout ${SONIC_COMMIT}"
        pre_patch_help
        exit
    fi

    date > ${FULL_PATH}/${LOG_FILE}
    [ -d patches ] || mkdir patches

    # Apply patch series
    apply_patch_series
    git submodule update
    # Apply patches
    #apply_patches
    # Apply submodule patches
    apply_submodule_patches
    # Apply hwsku changes
    apply_hwsku_changes
}

main $@
