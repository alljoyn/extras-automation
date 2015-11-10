
#    Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright (c) Open Connectivity Foundation and Contributors to AllSeen
#    Alliance. All rights reserved.
#
#    Permission to use, copy, modify, and/or distribute this software for
#    any purpose with or without fee is hereby granted, provided that the
#    above copyright notice and this permission notice appear in all
#    copies.
#
#     THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#     WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#     WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
#     AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
#     DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#     PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#     TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#     PERFORMANCE OF THIS SOFTWARE.

case "$cif_core_xcodebuilds_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_core_xcodebuilds_xet=cif_xet

echo >&2 + : BEGIN cif_core_xcodebuilds.sh

ci_xcode_vartags() {

    : ci_xcode_vartags "$@"

    case "$1" in
    ( [Dd]eb* | [Dd]bg )
        echo _variant=debug configuration=Debug vartag=dbg
        ;;
    ( [Rr]el* )
        echo _variant=release configuration=Release vartag=rel
        ;;
    ( * )
        ci_exit 2 $ci_job, ci_xcode_vartags argv1="$1"
        ;;
    esac
}
export -f ci_xcode_vartags

# function runs xcode builds for AllJoyn Std Core on Mac OSX for either Debug or Release,
# producing bins to run google tests and iphone simulator on a Mac
#   cwd     : top of AJ Std Core SCons build tree (ie core/alljoyn)
#   argv1=[Debug,Release]

ci_xcodebuild_simulator() {

    local xet="$-"
    local xit=0

    :
    : ci_xcodebuild_simulator "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    case "${CIAJ_GTEST}" in
    ( [NnFf]* ) unset GTEST_DIR ;;
    esac
    ci_savenv

    local project _variant configuration vartag
    eval $( ci_xcode_vartags "$1" )

    pushd alljoyn_objc
        :
        : START xcodebuild x86 / core $configuration
        :
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_osx -configuration $configuration \
            -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_osx"
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/x86/$_variant/dist"

        :
        : START xcodebuild simulator / core $configuration
        :
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios -sdk iphonesimulator -configuration $configuration PLATFORM_NAME=iphonesimulator \
            -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_ios-iphonesimulator"
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm/iphonesimulator/$_variant/dist"
    popd

    project=AllJoynFramework_iOS
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd alljoyn_objc/AllJoynFramework_iOS
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphonesimulator"
    popd

    project=alljoyn_about_cpp
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_cpp
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphonesimulator"
    popd

    project=alljoyn_about_objc
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_objc
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphonesimulator"
    popd

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_xcodebuild_simulator

# function runs xcode builds for AllJoyn Std Core on Mac OSX for either Debug or Release,
# producing bins for arm / ios
#   cwd     : top of AJ Std Core SCons build tree (ie core/alljoyn)
#   argv1=[Debug,Release]

ci_xcodebuild_arm() {

    local xet="$-"
    local xit=0

    :
    : ci_xcodebuild_arm "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    case "${CIAJ_GTEST}" in
    ( [NnFf]* ) unset GTEST_DIR ;;
    esac
    ci_savenv

    local project _variant configuration vartag
    eval $( ci_xcode_vartags "$1" )

    pushd alljoyn_objc
        :
        : START xcodebuild arm / core $configuration
        :
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_ios-iphoneos"
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm/iphoneos/$_variant/dist"

        :
        : START xcodebuild armv7 / core $configuration
        :
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios_armv7 -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_ios_armv7-iphoneos"
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/armv7/iphoneos/$_variant/dist"

        :
        : START xcodebuild armv7s / core $configuration
        :
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios_armv7s -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_ios_armv7s-iphoneos"
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/armv7s/iphoneos/$_variant/dist"

        case "${GERRIT_BRANCH}" in
        ( RB14.* )
            :
            : no arm64 until RB15.04
            :
            ;;
        ( * )
            :
            : START xcodebuild arm64 / core $configuration
            :
            xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_arm64 -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos \
                -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_arm64-iphoneos"
            ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm64/iphoneos/$_variant/dist"
            ;;
        esac
    popd

    project=AllJoynFramework_iOS
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd alljoyn_objc/AllJoynFramework_iOS
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphoneos"
    popd

    project=alljoyn_about_cpp
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_cpp
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphoneos"
    popd

    project=alljoyn_about_objc
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_objc
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos \
            -derivedDataPath "${CI_WORK}/DerivedData/$project-iphoneos"
    popd

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_xcodebuild_arm

# Like ci_xcodebuild_arm above, except it builds alljoyn_core for arm64 ONLY.
# Not useful, except added to a verify build it makes a quick sanity ck of recently-added arm64 support.
#   cwd     : top of AJ Std Core SCons build tree (ie core/alljoyn)
#   argv1=[Debug,Release]

ci_xcodebuild_arm64_only() {

    local xet="$-"
    local xit=0

    :
    : ci_xcodebuild_arm "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    case "${CIAJ_GTEST}" in
    ( [NnFf]* ) unset GTEST_DIR ;;
    esac
    ci_savenv

    local project _variant configuration vartag
    eval $( ci_xcode_vartags "$1" )

    pushd alljoyn_objc

        case "${GERRIT_BRANCH}" in
        ( RB14.* )
            :
            : no arm64 until RB15.04
            :
            ;;
        ( * )
            :
            : START xcodebuild arm64 / core $configuration
            :
            xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_arm64 -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos \
                -derivedDataPath "${CI_WORK}/DerivedData/alljoyn_darwin-alljoyn_core_arm64-iphoneos"
            ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm64/iphoneos/$_variant/dist"
            ;;
        esac
    popd

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_xcodebuild_arm64_only

    # end processing this file

echo >&2 + : END cif_core_xcodebuilds.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac