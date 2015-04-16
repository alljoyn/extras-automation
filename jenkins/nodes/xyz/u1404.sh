
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

# Xyzcity- AllJoyn- and Jenkins node-specific additions and overrides to ci_setenv
# ci_node_type=u1404 (Ubuntu 14.04)

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file

echo >&2 + : BEGIN xyz/u1404.sh

source "${CI_COMMON_PART}/${CI_SITE}/ci_setenv.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    # shares used by Xyzcity Jenkins

# CIXYZ_SDK   = provided through Jenkins Node env. = path to shared files containing SDKs copied daily from ASA
# CIXYZ_SHARE = provided through Jenkins Node env. = path to general-purpose static shared files

ci_ck_found CIXYZ_SHARE CIXYZ_SDK

export CIXYZ_SHOPT=${CIXYZ_SHARE}/opt
export CIXYZ_SHOPT_NODE=${CIXYZ_SHOPT}/node_types/${CI_NODETYPE}

ci_ck_found CIXYZ_SHOPT CIXYZ_SHOPT_NODE

    # common AllJoyn scons build resources installed on this node

export GECKO_BASE=/opt/xulrunner-sdk
export JSDOC_DIR=/opt/jsdoc-3.3.0-alpha9
export GTEST_DIR=${CIXYZ_SHOPT_NODE}/gtest-1.7.0

export JAVA_HOME=/opt/java/jdk1.7.0_67
export ANT_HOME=/opt/apache-ant-1.8.4
export CLASSPATH=/opt/java/lib/junit-4.11.jar
export JAVA6_BOOT=/opt/java/jdk1.6.0_45/jre/lib
unset  OPENSSL_ROOT

_uncrustify_bin=${CIXYZ_SHOPT_NODE}/uncrustify-0.61/bin
_kwbin=/opt/klocwork-10.0.6/install/bin

ci_ck_found GECKO_BASE JSDOC_DIR GTEST_DIR JAVA_HOME ANT_HOME CLASSPATH JAVA6_BOOT _uncrustify_bin _kwbin

case "${CIAJ_OS}" in
( android )
    # Android depends on API level, which is defined at build time
    case "${CIAJ_ANDROID_API_LEVEL}" in
    ( "" )
        unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDK_ROOT
        ;;
    ( 16 | 17 | 18 )
        export ANDROID_SDK=/opt/android-sdk-linux
        export ANDROID_NDK=/opt/android-ndk-r9d
        export ANDROID_SRC=/opt/android_jellybean_georgen
        ;;
    ( * )
        echo >&2 + : WARNING ANDROID_API_LEVEL="${CIAJ_ANDROID_API_LEVEL}" is not supported on this node
        # but good luck anyway
        export ANDROID_SDK=/opt/android-sdk-linux
        export ANDROID_NDK=/opt/android-ndk-r9d
        export ANDROID_SRC=/opt/android_jellybean_georgen
        ;;
    esac
    ci_ck_found ANDROID_SDK ANDROID_NDK ANDROID_SRC
    export SDK_ROOT=${ANDROID_SDK}
    export PATH=$PATH:$SDK_ROOT/tools:$SDK_ROOT/platform-tools:$ANDROID_NDK
    ;;
( * )
    unset CIAJ_ANDROID_API_LEVEL ANDROID_API_LEVEL
    unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDK_ROOT
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
