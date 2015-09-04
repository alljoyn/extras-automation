
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
ci_job=vfy-JS.sh
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
    _variant=release
    _vartag=rel
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/build/darwin/x86/$_variant/dist
    ;;
( alljoyn-*-win7*-sdk )
    :
    : SDK for win7
    :
    _variant=release
    _vartag=rel
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/${CIAJ_CORE_SDK}-$_vartag
    ;;
( alljoyn-*-android-sdk-dbg | alljoyn-*-android-sdk-rel )
    :
    : SDK for android
    :
    _variant=debug
    _vartag=dbg
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}/alljoyn-android/core/${CIAJ_CORE_SDK%-android-sdk-???}-${CIAJ_CORE_SDK#alljoyn-*-android-sdk-}
    ;;
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : SDK for linux
    :
    _variant=release
    _vartag=rel
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}
    ;;
( * )
    :
    : WARNING  SDK of unknown type : assume it starts at dist, and hope for the best
    :
    _variant=release
    _vartag=rel
    export ALLJOYN_DISTDIR=${CI_SCRATCH}/${CIAJ_CORE_SDK}
    ;;
esac
export ALLJOYN_DIST="$ALLJOYN_DISTDIR"  # the env var name changed after tc_reorg

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose=0 ;; ( * ) _verbose=1 ;; esac
case "$( uname )" in
( Linux )
    _ws=detail
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
        case "$r" in ( "" ) ;; ( * ) git checkout "$r" || : WARNING "$r not found $p.git, using master." ;; esac
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

:
: DUKTAPE
:
cd "${CI_WORK}"
rm -rf "${CIAJ_DUKTAPE}"
ci_unzip "${CIAJ_DUKTAPE_ZIP}"

ci_showfs "${CIAJ_DUKTAPE}"

:
: CIAJ_CORE_SDK
:
cd "${CI_SCRATCH}"
rm -rf "${CIAJ_CORE_SDK}"
ci_unzip "${CIAJ_CORE_SDK_ZIP}"

ci_showfs "${CIAJ_CORE_SDK}"
ci_showfs "${ALLJOYN_DISTDIR}"

cd "${WORKSPACE}"

:
: START build ajtcl
:

pushd alljoyn/core/ajtcl
    ci_scons V=$_verbose WS=off VARIANT=$_variant ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
popd

if ls -ld alljoyn/services/base_tcl/SConstruct
then
    :
    : START build base_tcl
    :
    pushd alljoyn/services/base_tcl
        ci_scons V=$_verbose WS=off EXCLUDE_ONBOARDING=yes VARIANT=$_variant ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
        ci_showfs
    popd
else
    :
    : WARNING no SConstruct in base_tcl / "${CIAJ_SERVICES_GITREV}"
    :
fi


:
: START build alljoyn-js
:

cd "${WORKSPACE}"
pushd alljoyn/core/alljoyn-js
    case "${GERRIT_BRANCH}" in
    ( RB15.04 ) # before tc_reorg
        if [ "$(uname)" = "Linux" -o "$(uname)" = "Darwin" ]; then
            ci_scons V=$_verbose WS=$_ws VARIANT=$_variant DUKTAPE_DIST="${CI_WORK}/${CIAJ_DUKTAPE}" JSDOCS=true JSDOC_DIR="${JSDOC_DIR}"
        else    # Windows desktop
            (
                export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )
                ci_scons V=$_verbose WS=$_ws VARIANT=$_variant DUKTAPE_DIST="$( ci_natpath "${CI_WORK}/${CIAJ_DUKTAPE}" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
            )
        fi
        ci_showfs

        :
        : START build console exe
        :
        cd console
        (
            export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )
            ci_scons V=$_verbose WS=$_ws VARIANT=$_variant ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
        )
        if [ "$(uname)" = "Linux" ]; then
            :
            : START python debugging console
            :
            python setup.py build
            ci_showfs
        elif [ "$(uname)" = "Darwin" ]; then
            :
            : WARNING python debugging console not implemented
            :
        else    # Windows desktop
            :
            : START python debugging console
            :
            (
                export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )
                export PATH=/c/Python34:$PATH   # custom hack Python version works w MSVS version > 2010
                export MSVC_VERSION=${CIAJ_MSVC_VERSION}
                python34 setup.py build
            )
            ci_showfs
        fi
        ;;
    ( * )       # after tc_reorg
        if [ "$(uname)" = "Linux" ]; then
            ci_scons V=$_verbose WS=$_ws VARIANT=$_variant DUKTAPE_SRC="${CI_WORK}/${CIAJ_DUKTAPE}/src" ALLJOYN_DIST="$ALLJOYN_DIST" JSDOCS=true JSDOC_DIR="${JSDOC_DIR}"
            pushd console
                :
                : START python debugging console
                :
                python setup.py build
                ci_showfs
            popd
        elif [ "$(uname)" = "Darwin" ]; then
            ci_scons V=$_verbose WS=$_ws VARIANT=$_variant DUKTAPE_SRC="${CI_WORK}/${CIAJ_DUKTAPE}/src" ALLJOYN_DIST="$ALLJOYN_DIST" JSDOCS=true JSDOC_DIR="${JSDOC_DIR}"
            :
            : WARNING python debugging console not implemented
            :
        else    # Windows desktop
            ci_scons V=$_verbose WS=$_ws VARIANT=$_variant DUKTAPE_SRC="$( ci_natpath "${CI_WORK}/${CIAJ_DUKTAPE}/src" )" ALLJOYN_DIST=$( ci_natpath "$ALLJOYN_DIST" )  ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
            pushd console
                :
                : WARNING - FIXME - temporarily disabled python debugging console build on Windows for master branch
                :
            #   :
            #   : START python debugging console
            #   :
            #   (
            #       export ALLJOYN_DIST=$( ci_natpath "$ALLJOYN_DIST" )
            #       export PATH=/c/Python34:$PATH   # custom hack Python version works w MSVS version > 2010
            #       export MSVC_VERSION=${CIAJ_MSVC_VERSION}
            #       python34 setup.py build
            #   )
            #   ci_showfs
            popd
        fi
        ci_showfs
        ;;
    esac
popd

:
: START artifacts
:

cd "${WORKSPACE}"

zip=${CI_ARTIFACT_NAME}-$_vartag
work=${CI_SCRATCH_ARTIFACTS}/$zip
to=${CI_ARTIFACTS}/$zip.zip

rm -rf "$work" "$to"    || : error ignored
mkdir -p "$work"        || : error ignored

cp alljoyn/manifest.txt "$work"

case "${GERRIT_BRANCH}" in
( RB15.04 ) # before tc_reorg
    pushd alljoyn/core/alljoyn-js
        : executables
        cp -p  alljoynjs   "$work" || cp -p  alljoynjs.exe "$work"
        pushd console
            cp -p  ajs_console "$work" || cp -p  ajs_console.exe "$work"
        popd
        : miscellany from src tree
        cp -rp js          "$work"
        cp -rp tools       "$work"
        cp -rp doc         "$work"
    popd
    if [ "$(uname)" = "Linux" ]; then
        : python debugging console shared lib
        mkdir "$work/lib" || : ok
        cp -p alljoyn/core/alljoyn-js/console/build/lib.*/AJSConsole.so "$work/lib"
        : ajtcl shared lib
        cp -p alljoyn/core/ajtcl/libajtcl.so "$work/lib"
    elif [ "$(uname)" = "Darwin" ]; then
        : python debugging console not implemented
    else    # Windows desktop
        : python debugging console - who knows?!
        mkdir "$work/site-packages" || : ok
        cp -p alljoyn/core/alljoyn-js/console/build/lib.*/AJSConsole.pyd    "$work/site-packages"
        cp -p alljoyn/core/alljoyn-js/console/site-packages/console/AJS*Console*.egg-info   "$work/site-packages" || : nice try though
    fi
    ;;
( * )       # after tc_reorg
    pushd alljoyn/core/alljoyn-js/dist
        : start with "dist" tree
        cp -rp *    "$work"
    popd
    pushd alljoyn/core/alljoyn-js
        : miscellany from src tree
        cp -rp js       "$work"
        cp -rp tools    "$work"
        cp -rp doc      "$work"
    popd
    if [ "$(uname)" = "Linux" ]; then
        : python debugging console shared lib
        mkdir "$work/lib" || : ok
        cp -p alljoyn/core/alljoyn-js/console/build/lib.*/AJSConsole.so "$work/lib"
        : ajtcl shared lib
        cp -p alljoyn/core/ajtcl/dist/lib/libajtcl.so "$work/lib"
        : base_tcl shared lib
        cp -p alljoyn/services/base_tcl/dist/lib/libajtcl_services.so "$work/lib"
    elif [ "$(uname)" = "Darwin" ]; then
        : python debugging console not implemented
    else    # Windows desktop
        : FIXME - disabled python debugging console build on Windows for master branch
    #   : python debugging console - who knows?!
    #   mkdir "$work/site-packages" || : ok
    #   cp -p alljoyn/core/alljoyn-js/console/build/lib.*/AJSConsole.pyd    "$work/site-packages"
    #   cp -p alljoyn/core/alljoyn-js/console/site-packages/AJS*Console*.egg-info   "$work/site-packages" || : nice try though
    fi
    ;;
esac

case "${CIAJ_CORE_SDK}" in
( alljoyn-*-linux*-sdk-dbg | alljoyn-*-linux*-sdk-rel )
    :
    : alljoyn core shared libs for linux
    :
    mkdir "$work/lib" || : ok

    pushd "${ALLJOYN_DISTDIR}"
        for i in about/lib/liballjoyn_about.so cpp/lib/liballjoyn.so ; do
            cp -p $i "$work/lib" || : not fatal yet
        done
        pushd "$work/lib"
            ls -ld liballjoyn* || ci_exit 2 $ci_job, "liballjoyn* (shared libs) not found in AJ Std Core SDK"
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
