
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

set -ex

source "${CI_NODE_SCRIPTS}/ci_setenv.sh"
ci_me=$( basename "$0" )

:
: START $ci_me
:

eval t="${CI_ARTIFACT_NAME}"
export CI_ARTIFACT_NAME="$t"
eval t="${AJ_CORE_GITREV}"
export AJ_CORE_GITREV="$t"
eval t="${AJ_SERVICES_GITREV}"
export AJ_SERVICES_GITREV="$t"
eval t="${AJ_CORE_SDK}"
export AJ_CORE_SDK="$t"
eval t="${HTTP_ASA_SDK}"
export HTTP_ASA_SDK="$t"
eval t="${DUKTAPE}"
export DUKTAPE="$t"

( CI_VERBOSE=True ; ci_showenv )

lci_ck_found LCI_DUKTAPE_ZIP

:
: START extra Gits
:

cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn-js ${GERRIT_BRANCH}  >  alljoyn/manifest.txt

case "${GIT_URL}" in
( */core/alljoyn-js.git )   b=${GIT_URL%/core/alljoyn-js.git} ;;
( */core/alljoyn-js )       b=${GIT_URL%/core/alljoyn-js} ;;
( * )   : ERROR trap "GIT_URL=${GIT_URL}" ; exit 2 ;;
esac
for p in core/ajtcl services/base_tcl services/base ; do

    :
    : clone $p
    :

    rm -rf alljoyn/$p ; git clone "$b/$p.git" alljoyn/$p

    case $p in
    ( core/alljoyn  | core/ajtcl )          r="${AJ_CORE_GITREV}" ;;
    ( services/base | services/base_tcl )   r="${AJ_SERVICES_GITREV}" ;;
    esac

    pushd alljoyn/$p
        case "$r" in ( "" ) ;; ( * ) git checkout "$r" || : WARNING, "$r not found $p.git, using master." ;; esac
        git log -1
    popd
    ci_genversion alljoyn/$p >> alljoyn/manifest.txt
done

: INFO show manifest

cat alljoyn/manifest.txt

ci_showfs alljoyn/core/alljoyn-js alljoyn/core/ajtcl alljoyn/services/base_tcl alljoyn/services/base

:
: START extra Libs
:

cd "${WCI_SCRATCH}"

:
: DUKTAPE
:
rm -rf "${DUKTAPE}"
ci_unzip "${LCI_DUKTAPE_ZIP}"

ci_showfs "${DUKTAPE}"

:
: AJ_CORE_SDK
:
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
    :
    : SDK for osx_ios
    :
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/build/darwin/x86/release/dist"
    ;;
( alljoyn-*-win7*-sdk )
    :
    : SDK for win7
    :
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/${AJ_CORE_SDK}-rel"
    ;;
( alljoyn-*-android-sdk-dbg | alljoyn-*-android-sdk-rel )
    :
    : SDK for android
    :
    export ALLJOYN_DISTDIR="${WCI_SCRATCH}/${AJ_CORE_SDK}/alljoyn-android/core/${AJ_CORE_SDK%-android-sdk-???}-${AJ_CORE_SDK#alljoyn-*-android-sdk-}"
    ;;
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : SDK for linux
    :
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

case "${CI_VERBOSE}" in ( [NnFf]* ) verbose=0 ;; ( * ) verbose=1 ;; esac
export ALLJOYN_DISTDIR_PREV="$ALLJOYN_DISTDIR"
export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )

:
: START build ajtcl
:

pushd alljoyn/core/ajtcl
    ci_scons WS=off VARIANT=release
popd

ci_showfs alljoyn/core/alljoyn/build/linux/x86_64/release/dist alljoyn/core/ajtcl

:
: START build alljoyn-js
:

cd "${WORKSPACE}"
pushd alljoyn/core/alljoyn-js
    ci_scons WS=off VARIANT=release DUKTAPE_DIST="$( ci_natpath "${WCI_SCRATCH}/${DUKTAPE}" )"
    ci_showfs

    :
    : START build console
    :
    cd console
    ci_scons WS=off VARIANT=release
    ci_showfs
popd

export ALLJOYN_DISTDIR="$ALLJOYN_DISTDIR_PREV"

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
pushd alljoyn/core/alljoyn-js
    cp -p  alljoynjs   "$a1" || cp -p  alljoynjs.exe "$a1"
    cp -rp js          "$a1"
    cp -rp tools       "$a1"
    cd console
    cp -p  ajs_console "$a1" || cp -p  ajs_console.exe "$a1"
popd

case "${AJ_CORE_SDK}" in
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : alljoyn shared libs for linux
    :
    mkdir "$a1/lib"

    pushd "${ALLJOYN_DISTDIR}"
        for i in about/lib/liballjoyn_about.so cpp/lib/liballjoyn.so ; do
            cp -p $i "$a1/lib" || : not fatal yet
        done
        pushd "$a1/lib"
            ls -l liballjoyn* || ci_exit 2 "liballjoyn* (shared libs) not found in AJ Core Std SDK"
        popd
    popd
    ;;
esac

pushd "$a1/.."
    : INFO show $d1.zip
    find "$d1" -type f -ls
    ci_zip "$z1" "$d1"
popd

cd "${WCI_ARTIFACTS}"
ci_showfs
rm -rf "${WCI_ARTIFACTS_WORK}"

: END $ci_me
