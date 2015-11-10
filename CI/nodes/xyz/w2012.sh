
# Copyright (c) 2016 Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright 2016 Open Connectivity Foundation and Contributors to
#    AllSeen Alliance. All rights reserved.
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
# ci_node_type=w2012 (Microsoft Windows Server 2012, with either MSYSGit or Cygwin)

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file

echo >&2 + : BEGIN xyz/w2012.sh

source "${CI_COMMON_PART}/xyz/ci_setenv.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    # shares used by Xyzcity Jenkins

# CI_DEPOT = provided through Jenkins Node env. = path to subtree containing saved SDKs, as mounted this node
# CI_SHARE = provided through Jenkins Node env. = path to general-purpose static shared files, as mounted this node

ci_ck_found CI_SHARE CI_DEPOT

export CI_SHOPT=${CI_SHARE}/opt
export CI_SHOPT_NODE=${CI_SHOPT}/node_types/${CI_NODETYPE}

ci_ck_found CI_SHOPT CI_SHOPT_NODE

    # common AllJoyn scons build resources installed on this node

unset GECKO_BASE
unset JSDOC_DIR
export GTEST_DIR=${CI_SHOPT_NODE}/gtest-1.7.0

# JAVA_HOME= see below
export ANT_HOME=/c/Install/apache-ant-1.8.2
export CLASSPATH=/c/Install/Java/lib/junit-4.8.2.jar
unset JAVA6_BOOT
unset OPENSSL_ROOT

ci_ck_found GTEST_DIR ANT_HOME CLASSPATH

case "${CIAJ_OS}" in
( android )
    echo >&2 + : WARNING this node does not support Android. CIAJ_OS="${CIAJ_OS}"
    ;;
( * )
    unset CIAJ_ANDROID_API_LEVEL ANDROID_API_LEVEL
    unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDKROOT
    ;;
esac

export IARBUILD=/c/Install/IAR/EW7.0/common/bin/IarBuild.exe
export EFM32_DIR=/c/Install/IAR/efm32-leopardgecko
export DOXYGEN_HOME=/c/Install/doxygen
export GRAPHVIZ_HOME=/c/Install/Graphviz2.38

_doxygen_bin=$DOXYGEN_HOME/bin
_dot_bin=$GRAPHVIZ_HOME/bin
_kwbin=/c/Klocwork/Server10.0/install/bin

_uncrustify_061=${CI_SHOPT_NODE}/uncrustify-0.61/bin/uncrustify.exe
_uncrustify_057=/c/Install/uncrustify-0.57-win32/uncrustify.exe

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

ci_ck_found IARBUILD EFM32_DIR _doxygen_bin _dot_bin _uncrustify_bin _kwbin

    # use the Java that goes with the given scons CPU type

case "${CIAJ_CPU}" in
( *64* )    export JAVA_HOME=/c/Install/Java/x64/jdk1.7.0_55 ;;
( *86* )    export JAVA_HOME=/c/Install/Java/x86/jdk1.7.0_55 ;;
( * )       export JAVA_HOME=/c/Install/Java/x64/jdk1.7.0_55 ;;
esac
ci_ck_found JAVA_HOME

    # set final PATH

export PATH=$ANT_HOME/bin:$JAVA_HOME/bin:$_doxygen_bin:$_dot_bin:$_uncrustify_bin:$_kwbin:$PATH

case "${CI_SHELL_W}" in
( "" )  # not Windows
    ;;
( * )   # Windows with msysgit or cygwin

    # extend ci_setenv.bat file for CMD processes to use later

    cat <<EOF | sed -e 's/$/\r/' >> "${CI_ARTIFACTS_ENV}/ci_setenv.bat"

    REM xyz/w2012.sh

$(
    declare -Fx | sed -e 's,^.* ,,' | while read -r i
    do
        case "$i" in
        ( "" )  ;;
        ( * )   echo "set $i=" ;;
        esac
    done
)
set PATH=$( ci_natpath "$ANT_HOME/bin" );$( ci_natpath "$JAVA_HOME/bin" );$( ci_natpath "$_kwbin" );$( ci_natpath "$_doxygen_bin" );$( ci_natpath "$_dot_bin" );$( ci_natpath "$_uncrustify_bin" );%PATH%
set ANT_HOME=$( ci_natpath "$ANT_HOME" )
set CLASSPATH=$( ci_natpath "$CLASSPATH" )
set JAVA_HOME=$( ci_natpath "$JAVA_HOME" )
set CI_DEPOT=$( ci_natpath "${CI_DEPOT}" )
set GTEST_DIR=$( ci_natpath "$GTEST_DIR" )
set CI_SHARE=$( ci_natpath "${CI_SHARE}" )
set CI_SHOPT=$( ci_natpath "${CI_SHARE}/opt" )
set CI_SHOPT_NODE=$( ci_natpath "${CI_SHOPT}/node_types/${CI_NODETYPE}" )
set IARBUILD=$( ci_natpath "$IARBUILD" )
set EFM32_DIR=$( ci_natpath "$EFM32_DIR" )
set DOXYGEN_HOME=$( ci_natpath "$DOXYGEN_HOME" )
set GRAPHVIZ_HOME=$( ci_natpath "$GRAPHVIZ_HOME" )
set CIXYZ_TEST_TOOLS=$( ci_natpath "$CIXYZ_TEST_TOOLS" )
EOF
    case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) : INFO show ci_setenv.bat, extended ; cat "${CI_ARTIFACTS_ENV}/ci_setenv.bat" ;; esac

        # a job may call unit test, etc directly from bash, without going through Windows CMD as we do for scons
        # if so, the native Windows tools that use these variables will expect native Windows paths
    export JAVA_HOME=$( ci_natpath "$JAVA_HOME" )
    export ANT_HOME=$( ci_natpath "$ANT_HOME" )
    export CLASSPATH=$( ci_natpath "$CLASSPATH" )
    export DOXYGEN_HOME=$( ci_natpath "$DOXYGEN_HOME" )
    export GRAPHVIZ_HOME=$( ci_natpath "$GRAPHVIZ_HOME" )
    ;;
esac

        # end processing this file
ci_savenv
case "$ci_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
echo >&2 + : END xyz/w2012.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac