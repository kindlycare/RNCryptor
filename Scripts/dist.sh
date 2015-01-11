#!/bin/sh
#  

function failed()
{
    echo "Build failed: $1" >&2
    exit $2
}

function check_env()
{
    if [ -z "${TARGETENV}" ] ||
         [ "${TARGETENV}" == "DEV" ] ||
         [ "${TARGETENV}" == "DEMO" ] ||
         [ "${TARGETENV}" == "STAGING" ] ||
         [ "${TARGETENV}" == "PRODUCTION" ]; then
        return 0
    fi

    return 1
}

function build_sdk()
{
    xcodebuild -configuration $cfg -sdk $sdk clean;

    #environment
    if [ -z "${TARGETENV}" ]; then
        echo "No environment specified, building with the default: [development]"
        xcodebuild -configuration $cfg -sdk $sdk || failed "${sdk}-${cfg} failed to build" $?
    else
        echo "Building with the specified environment: [${TARGETENV}]"
        xcodebuild GCC_PREPROCESSOR_DEFINITIONS="${TARGETENV}=1" -configuration $cfg -sdk $sdk || failed "${sdk}-${cfg} failed to build" $?
    fi
}

function buildall()
{
    for cfg in $CONFIGURATION; do
        for sdk in $SDKS; do
        
            #build sdk using configuration
            build_sdk
        done

        lib_386=build/${cfg}-iphonesimulator/lib${LIBNAME}.a
        lib_arm=build/${cfg}-iphoneos/lib${LIBNAME}.a
        lib_fat=lib${FRAMEWORKNAME}.a

        if [ ${cfg} == "Debug" ]; then
            lib_fat=lib${FRAMEWORKNAME}-d.a
        fi

        lipo -create ${lib_arm} ${lib_386} -output build/dist/${lib_fat}
    done
}

#artifacts
LIBNAME="RNCryptor"
FRAMEWORKNAME="RNCryptor"

#configuration
SDKS="iphoneos iphonesimulator"

#CONFIGURATION="Debug Release" uncomment if you want debug configurations built
CONFIGURATION="Release"

#environment
TARGETENV=$1
check_env || failed "${TARGETENV} is not supported - choose one: \r\n [DEV] (default if ommitted) \r\n [DEMO] \r\n [STAGING] \r\n [PRODUCTION]" 1

#clean before creating new distribution
rm -rf build/dist
mkdir -p build/dist/Headers

#build all artifacts
buildall

#copy headers
find build/${cfg}-iphoneos/include -name '*.h' -exec cp {} build/dist/Headers \;
