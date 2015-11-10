
# #    Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
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
# ci_node_type=o1010 (Mac OS X)

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file

echo >&2 + : BEGIN xyz/o1010.sh

source "${CI_COMMON_PART}/${CI_SITE}/ci_setenv.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    # number of processors on a Mac

_n=$( sysctl -n hw.logicalcpu || echo >&2 + : WARNING xyz/o1010.sh, system error from sysctl )
case "$_n" in
( "" | *[!0-9]* | 0 )
    echo >&2 + : WARNING xyz/o1010.sh, bad or invalid hw.logicalcpu="$_n"
    # NUMBER_OF_PROCESSORS=1 from ci_setenv
    ;;
( * )
    export NUMBER_OF_PROCESSORS=$_n
    ;;
esac

    # shares used by Xyzcity Jenkins

# CI_DEPOT = provided through Jenkins Node env. = path to subtree containing saved SDKs, as mounted this node
# CI_SHARE = provided through Jenkins Node env. = path to general-purpose static shared files, as mounted this node

ci_ck_found CI_SHARE CI_DEPOT

export CI_SHOPT=${CI_SHARE}/opt
export CI_SHOPT_NODE=${CI_SHOPT}/node_types/${CI_NODETYPE}

ci_ck_found CI_SHOPT CI_SHOPT_NODE

    # common AllJoyn scons build resources installed on this node

unset GECKO_BASE
export JSDOC_DIR=/usr/local/lib/node_modules/jsdoc
export GTEST_DIR="${CI_SHOPT_NODE}/gtest-1.7.0"

unset JAVA_HOME
unset ANT_HOME
unset CLASSPATH
unset JAVA6BOOT
export OPENSSL_ROOT="${CI_SHOPT_NODE}/openssl-1.0.1m"

ci_ck_found JSDOC_DIR GTEST_DIR OPENSSL_ROOT

case "${CIAJ_OS}" in
( android )
    echo >&2 + : WARNING this node does not support Android. CIAJ_OS="${CIAJ_OS}"
    ;;
( * )
    unset ANDROID_SDK ANDROID_NDK ANDROID_SRC SDK_ROOT
    unset CIAJ_ANDROID_API_LEVEL ANDROID_API_LEVEL
    ;;
esac

    # set final PATH

# export PATH=$ANT_HOME/bin:$JAVA_HOME/bin:$PATH    # NO CHANGE

    # add some ulimits

ulimit -n 4096
ulimit -u 1024
ulimit -c unlimited

        # end processing this file
ci_savenv
case "$ci_xet" in ( *x* ) set -x ;; ( * ) set -x ;; esac
echo >&2 + : END xyz/o1010.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac