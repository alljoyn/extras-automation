
# Copyright AllSeen Alliance. All rights reserved.
#
#    Permission to use, copy, modify, and/or distribute this software for any
#    purpose with or without fee is hereby granted, provided that the above
#    copyright notice and this permission notice appear in all copies.
#
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

echo >&2 + : BEGIN cif_core_xcodebuilds.sh

ci_xcode_vartags() {

    : ci_xcode_vartags "$@"

    case "$1" in
    ( [Dd]eb* | [Dd]bg )
        echo variant=debug configuration=Debug vartag=dbg
        ;;
    ( [Rr]el* )
        echo variant=release configuration=Release vartag=rel
        ;;
    ( * )
        ci_exit 2 $ci_job, ci_xcode_vartags argv1="$1"
        ;;
    esac
}
export -f ci_xcode_vartags

# function runs xcode builds for AllJoyn Core on Mac OSX for either Debug or Release,
# producing bins to run google tests and iphone simulator on a Mac
#   cwd     : top of AJ Core SCons build tree (ie core/alljoyn)
#   argv1=[Debug,Release]

ci_xcodebuild_simulator() {

    : ci_xcodebuild_simulator "$@"

    local project variant configuration vartag
    eval $( ci_xcode_vartags "$1" )

    :
    : START xcodebuild simulator / core $configuration
    :
    pushd alljoyn_objc
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_osx -configuration $configuration
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/x86/$variant/dist"

        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios -sdk iphonesimulator -configuration $configuration PLATFORM_NAME=iphonesimulator
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm/iphonesimulator/$variant/dist"
    popd

    project=AllJoynFramework_iOS
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd alljoyn_objc/AllJoynFramework_iOS
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator
    popd

    project=alljoyn_about_cpp
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_cpp
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator
    popd

    project=alljoyn_about_objc
    :
    : START xcodebuild simulator / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_objc
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphonesimulator
    popd
}
export -f ci_xcodebuild_simulator

# function runs xcode builds for AllJoyn Core on Mac OSX for either Debug or Release,
# producing bins for arm / ios
#   cwd     : top of AJ Core SCons build tree (ie core/alljoyn)
#   argv1=[Debug,Release]

ci_xcodebuild_arm() {

    : ci_xcodebuild_arm "$@"

    local project variant configuration vartag
    eval $( ci_xcode_vartags "$1" )

    :
    : START xcodebuild arm / core $configuration
    :
    pushd alljoyn_objc
        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/arm/iphoneos/$variant/dist"

        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios_armv7 -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/armv7/iphoneos/$variant/dist"

        xcodebuild -project alljoyn_darwin.xcodeproj -scheme alljoyn_core_ios_armv7s -sdk iphoneos -configuration $configuration PLATFORM_NAME=iphoneos
        ci_showfs "${WORKSPACE}/alljoyn/core/alljoyn/build/darwin/armv7s/iphoneos/$variant/dist"
    popd

    project=AllJoynFramework_iOS
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd alljoyn_objc/AllJoynFramework_iOS
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos
    popd

    project=alljoyn_about_cpp
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_cpp
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos
    popd

    project=alljoyn_about_objc
    :
    : START xcodebuild arm / $project $configuration
    :
    pushd services/about/ios/samples/alljoyn_services_objc
        xcodebuild -project $project.xcodeproj -scheme $project ONLY_ACTIVE_ARCHS=NO -configuration $configuration -sdk iphoneos
    popd
}
export -f ci_xcodebuild_arm

echo >&2 + : END cif_core_xcodebuilds.sh
