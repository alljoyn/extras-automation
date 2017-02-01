
#    Copyright (c) Open Connectivity Foundation (OCF), AllJoyn Open Source
#    Project (AJOSP) Contributors and others.
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
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#    WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#    WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
#    AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
#    DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#    PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#    TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#    PERFORMANCE OF THIS SOFTWARE.
ci_me=$( basename "$0" )
set -ex

:
: START $ci_me
:
source "${CI_NODE_SCRIPTS}/ci_setenv.sh"

( CI_VERBOSE=True ; ci_showenv ; ci_showfs )

set -x

cd "${WORKSPACE}"

python "${WCI_GENVERSION_PY}" alljoyn/core/alljoyn-js ${GERRIT_BRANCH}  >  alljoyn/manifest.txt

: INFO show manifest

cat alljoyn/manifest.txt

:
: START AJ_CORE_SDK
:
cd "${WCI_SCRATCH}"
rm -rf "${AJ_CORE_SDK}" "${AJ_CORE_SDK}.zip"

# one or the other should work
wget -nv --no-check-certificate "${HTTP_ASA_SDK}/${AJ_CORE_SDK}.zip" && ci_unzip "${AJ_CORE_SDK}.zip" || {
    curl -s -k -f -o "${AJ_CORE_SDK}.zip" "${HTTP_ASA_SDK}/${AJ_CORE_SDK}.zip" && ci_unzip "${AJ_CORE_SDK}.zip" || exit 2
}
ci_showfs "${AJ_CORE_SDK}"

:
: set ALLJOYN_DISTDIR according to type of AJ_CORE_SDK=${AJ_CORE_SDK}
:
case "${AJ_CORE_SDK}" in
( alljoyn-*-osx_ios-sdk )
    : SDK for osx_ios
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/build/darwin/x86/release/dist"
    ;;
( alljoyn-*-win7*-sdk )
    : SDK for win7
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/${AJ_CORE_SDK}-rel"
    ;;
( alljoyn-*-android-sdk-dbg | alljoyn-*-android-sdk-rel )
    : SDK for android
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/alljoyn-android/core/${AJ_CORE_SDK%-android-sdk-???}-${AJ_CORE_SDK#alljoyn-*-android-sdk-}"
    ;;
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    : SDK for linux
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}"
    ;;
( * )
    :
    : WARNING  SDK of unknown type : assume it starts at dist, and hope for the best
    :
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}"
    ;;
esac

ci_showfs "${ALLJOYN_DISTDIR}"

cd "${WORKSPACE}"

pushd alljoyn/core/alljoyn-js
    :
    : START build console
    :
    cd console
    scons WS=off VARIANT=release
    ci_showfs
popd

:
: START artifacts
:
cd "${WORKSPACE}"

d1=${CI_ARTIFACT_NAME}
a1="${WCI_ARTIFACTS_WORK}/$d1"
z1="${WCI_ARTIFACTS}/$d1.zip"
(
    set +e
    rm -rf "$a1" "$z1"
    mkdir -p "$a1"
) || : error ignored

cp alljoyn/manifest.txt "$a1"

case "${AJ_CORE_SDK}" in
( alljoyn-*-osx_ios-sdk )
    : artifact for osx
    pushd alljoyn/core/alljoyn-js
        cd console
        cp -p  ajs_console "$a1"
    popd
    ;;
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    : artifact for linux
    pushd alljoyn/core/alljoyn-js
        cd console
        cp -p  ajs_console "$a1"
    popd

    # alljoyn shared libs
    mkdir "$a1/lib"

    pushd "${ALLJOYN_DISTDIR}"
        for i in about/lib/liballjoyn_about.so cpp/lib/liballjoyn.so ; do
            cp -p $i "$a1/lib" || : not fatal
        done
        pushd "$a1/lib"
            ls -l * # fatal
        popd
    popd
    ;;
( * )
    :
    : ERROR trap, artifacts for AJ_CORE_SDK=${AJ_CORE_SDK}
    :
    exit 2
    ;;
esac

pushd "$a1/.."
    : INFO show "$d1.zip"
    find "$d1" -type f -ls
    ci_zip "$z1" "$d1"
popd

cd "${WCI_ARTIFACTS}"
ci_showfs
rm -rf "${WCI_ARTIFACTS_WORK}"

: END $ci_me
