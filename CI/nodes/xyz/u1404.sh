
# Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
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

# Xyzcity- AllJoyn- and Jenkins node-specific additions and overrides to ci_setenv
# ci_node_type=u1404 (Ubuntu 14.04)

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file

echo >&2 + : BEGIN xyz/u1404.sh

source "${CI_COMMON_PART}/${CI_SITE}/ci_setenv.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    # shares used by Xyzcity Jenkins

# CI_DEPOT = provided through Jenkins Node env. = path to subtree containing saved SDKs, as mounted this node
# CI_SHARE = provided through Jenkins Node env. = path to general-purpose static shared files, as mounted this node

ci_ck_found CI_SHARE CI_DEPOT

export CI_SHOPT=${CI_SHARE}/opt
export CI_SHOPT_NODE=${CI_SHOPT}/node_types/${CI_NODETYPE}

ci_ck_found CI_SHOPT CI_SHOPT_NODE

    # common AllJoyn scons build resources installed on this node

export GECKO_BASE=/opt/xulrunner-sdk
export JSDOC_DIR=/usr/lib/node_modules/jsdoc
export GTEST_DIR=${CI_SHOPT_NODE}/gtest-1.7.0

export JAVA_HOME=/opt/java/jdk1.7.0_67
export ANT_HOME=/opt/apache-ant-1.8.4
export CLASSPATH=/opt/java/lib/junit-4.11.jar
export JAVA6_BOOT=/opt/java/jdk1.6.0_45/jre/lib
unset  OPENSSL_ROOT

_kwbin=/opt/klocwork-10.0.6/install/bin
_uncrustify_061=${CI_SHOPT_NODE}/uncrustify-0.61/bin/uncrustify
_uncrustify_057=/opt/bin/uncrustify

case "${GERRIT_BRANCH}" in
( RB14.* )
    "$_uncrustify_057" --version
    _uncrustify_bin=$( dirname "$_uncrustify_057" )
    ;;
( * )
    "$_uncrustify_061" --version
    _uncrustify_bin=$( dirname "$_uncrustify_061" )
    ;;
esac

ci_ck_found GECKO_BASE JSDOC_DIR GTEST_DIR JAVA_HOME ANT_HOME CLASSPATH JAVA6_BOOT _uncrustify_bin _kwbin

case "${CIAJ_OS}" in
( android )
    # Android depends on API level, which is defined at build time
    case "${CIAJ_ANDROID_API_LEVEL}" in
    ( "" )
        unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDK_ROOT
        ;;
    ( 16 | 17 | 18 )
        case "${GERRIT_BRANCH}" in
        ( RB14.* | RB15.04 )
            export ANDROID_SDK=/opt/android-sdk-linux
            export ANDROID_NDK=/opt/android-ndk-r9d
            export ANDROID_SRC=/opt/android_jellybean_georgen
            ci_ck_found ANDROID_SRC
            ;;
        ( * )
            export ANDROID_SDK=${CI_SHOPT_NODE}/android-sdk-linux
            export ANDROID_NDK=${CI_SHOPT_NODE}/android-ndk-r10e
            case "${CIAJ_CRYPTO}" in
            ( openssl )
                export ANDROID_SRC=/opt/android_jellybean_georgen
                ci_ck_found ANDROID_SRC
                ;;
            ( builtin | * )
                unset ANDROID_SRC
                ;;
            esac
            ;;
        esac
        ;;
    ( * )
        ci_exit 2 ANDROID_API_LEVEL="${CIAJ_ANDROID_API_LEVEL}" is not supported on this node
        ;;
    esac
    export ALLJOYN_ANDROID_KEYSTORE=/opt/AllJoyn_KeyStore/AllJoyn_KeyStore
    export ALLJOYN_ANDROID_KEYSTORE_PW=/opt/AllJoyn_KeyStore/.password
    export ALLJOYN_ANDROID_KEYSTORE_ALIAS=AllJoyn
    ci_ck_found ANDROID_SDK ANDROID_NDK ALLJOYN_ANDROID_KEYSTORE ALLJOYN_ANDROID_KEYSTORE_PW

    export SDK_ROOT=${ANDROID_SDK}
    export PATH=$PATH:$SDK_ROOT/tools:$SDK_ROOT/platform-tools:$ANDROID_NDK
    ;;
( * )
    unset CIAJ_ANDROID_API_LEVEL ANDROID_API_LEVEL
    unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDK_ROOT ALLJOYN_ANDROID_KEYSTORE ALLJOYN_ANDROID_KEYSTORE_PW
    ;;
esac

    # set final PATH

export PATH=$ANT_HOME/bin:$JAVA_HOME/bin:$_uncrustify_bin:$_kwbin:$PATH

    # add some ulimits
ulimit -n 4096
ulimit -u 1024
ulimit -c unlimited

        # end processing this file
ci_savenv
case "$ci_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
echo >&2 + : END xyz/u1404.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac