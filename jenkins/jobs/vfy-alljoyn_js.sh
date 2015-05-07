
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

# Gerrit-verify build for AllJoyn-Javascript on any platform

set -e +x
ci_job=vfy-alljoyn_js.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

eval _t="${CI_ARTIFACT_NAME}"
export CI_ARTIFACT_NAME=$_t
eval _t="${CIAJ_CORE_GITREV}"
export CIAJ_CORE_GITREV=$_t
eval _t="${CIAJ_SERVICES_GITREV}"
export CIAJ_SERVICES_GITREV=$_t
eval _t="${CIAJ_CORE_SDK}"
export CIAJ_CORE_SDK=$_t
eval _t="${CIAJ_DUKTAPE}"
export CIAJ_DUKTAPE=$_t

export CIAJ_DUKTAPE_ZIP=${CISEA_SHOPT}/common/${CIAJ_DUKTAPE}.zip
export CIAJ_CORE_SDK_ZIP=$( find "${CISEA_SDK}" -type f -name "${CIAJ_CORE_SDK}.zip" )

ci_ck_found CIAJ_DUKTAPE_ZIP || ci_exit 2 $ci_job, CIAJ_DUKTAPE_ZIP="${CIAJ_DUKTAPE_ZIP}" not found
ci_ck_found CIAJ_CORE_SDK_ZIP || ci_exit 2 $ci_job, CIAJ_CORE_SDK_ZIP="${CISEA_SDK}/**/${CIAJ_CORE_SDK}.zip" not found

:
: set ALLJOYN_DISTDIR according to type of CIAJ_CORE_SDK=${CIAJ_CORE_SDK}
:
case "${CIAJ_CORE_SDK}" in
( alljoyn-*-osx_ios-sdk )
    :
    : SDK for osx_ios
    :
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/build/darwin/x86/release/dist
    ;;
( alljoyn-*-win7*-sdk )
    :
    : SDK for win7
    :
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/${CIAJ_CORE_SDK}-rel
    ;;
( alljoyn-*-android-sdk-dbg | alljoyn-*-android-sdk-rel )
    :
    : SDK for android
    :
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/alljoyn-android/core/${CIAJ_CORE_SDK%-android-sdk-???}-${CIAJ_CORE_SDK#alljoyn-*-android-sdk-}
    ;;
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : SDK for linux
    :
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}
    ;;
( * )
    :
    : WARNING  SDK of unknown type : assume it starts at dist, and hope for the best
    :
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}
    ;;
esac

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

case "$( uname )" in
( Linux )
    _uncrustify=$( uncrustify --version ) || : ok
    case "$_uncrustify" in
    ( uncrustify* )
        case "${GERRIT_BRANCH}/$_uncrustify" in
        ( */uncrustify\ 0.61* )
            _ws=detail
            ;;
        ( * )
            _ws=off
            :
            : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
            :
            ;;
        esac
        ;;
    ( * )
        _ws=off
        :
        : WARNING $ci_job, uncrustify not found: skipping Whitespace scan
        :
        ;;
    esac
    ;;
( * )
    _ws=off
    ;;
esac

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn-js ${GERRIT_BRANCH}  >  alljoyn/manifest.txt

:
: START extra Gits
:

case "${GIT_URL}" in
( */core/alljoyn-js.git )   b=${GIT_URL%/core/alljoyn-js.git} ;;
( */core/alljoyn-js )       b=${GIT_URL%/core/alljoyn-js} ;;
( * )   ci_exit 2 $ci_job, trap "GIT_URL=${GIT_URL}" ;;
esac
for p in core/ajtcl services/base_tcl services/base ; do

    :
    : clone $p
    :

    rm -rf alljoyn/$p ; git clone "$b/$p.git" alljoyn/$p

    case $p in
    ( core/alljoyn  | core/ajtcl )          r="${CIAJ_CORE_GITREV}" ;;
    ( services/base | services/base_tcl )   r="${CIAJ_SERVICES_GITREV}" ;;
    esac

    pushd alljoyn/$p
        case "$r" in ( "" ) ;; ( * ) git checkout "$r" || : WARNING, "$r not found $p.git, using master." ;; esac
        git log -1
        ci_showfs
    popd
    ci_genversion alljoyn/$p >> alljoyn/manifest.txt
done

: INFO manifest

cp alljoyn/manifest.txt artifacts
cat alljoyn/manifest.txt

:
: START extra Libs
:

cd "${CI_SCRATCH}"

:
: DUKTAPE
:
rm -rf "${CIAJ_DUKTAPE}"
ci_unzip "${CIAJ_DUKTAPE_ZIP}"

ci_showfs "${CIAJ_DUKTAPE}"

:
: CIAJ_CORE_SDK
:
rm -rf "${CIAJ_CORE_SDK}"
ci_unzip "${CIAJ_CORE_SDK_ZIP}"

ci_showfs "${CIAJ_CORE_SDK}"
ci_showfs "${ALLJOYN_DISTDIR}"

cd "${WORKSPACE}"

case "${CI_VERBOSE}" in ( [NnFf]* ) verbose=0 ;; ( * ) verbose=1 ;; esac

:
: START build ajtcl
:

pushd alljoyn/core/ajtcl
    ci_scons WS=off VARIANT=release ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
popd

:
: START build alljoyn-js
:

cd "${WORKSPACE}"
pushd alljoyn/core/alljoyn-js
    (
        export ALLJOYN_DISTDIR="$( ci_natpath "$ALLJOYN_DISTDIR" )"
        ci_scons WS=$_ws VARIANT=release DUKTAPE_DIST="$( ci_natpath "${CI_SCRATCH}/${CIAJ_DUKTAPE}" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    )
    ci_showfs

    :
    : START build console
    :
    cd console
    (
        export ALLJOYN_DISTDIR="$( ci_natpath "$ALLJOYN_DISTDIR" )"
        ci_scons WS=$_ws VARIANT=release ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    )
    ci_showfs
popd

:
: START artifacts
:

cd "${WORKSPACE}"

zip=${CI_ARTIFACT_NAME}
work=${CI_ARTIFACTS_WORK}/$zip
to=${CI_ARTIFACTS}/$zip.zip

rm -rf "$work" "$to"    || : error ignored
mkdir -p "$work"        || : error ignored

cp alljoyn/manifest.txt "$work"
pushd alljoyn/core/alljoyn-js
    cp -p  alljoynjs   "$work" || cp -p  alljoynjs.exe "$work"
    cp -rp js          "$work"
    cp -rp tools       "$work"
    cd console
    cp -p  ajs_console "$work" || cp -p  ajs_console.exe "$work"
popd

case "${CIAJ_CORE_SDK}" in
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : alljoyn shared libs for linux
    :
    mkdir "$work/lib"

    pushd "${ALLJOYN_DISTDIR}"
        for i in about/lib/liballjoyn_about.so cpp/lib/liballjoyn.so ; do
            cp -p $i "$work/lib" || : not fatal yet
        done
        pushd "$work/lib"
            ls -l liballjoyn* || ci_exit 2 $ci_job, "liballjoyn* (shared libs) not found in AJ Core Std SDK"
        popd
    popd
    ;;
esac

pushd "$work/.."
    : INFO show $zip.zip
    find "$zip" -type f -ls
    ci_zip "$to" "$zip"
popd

rm -rf "$work"

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
