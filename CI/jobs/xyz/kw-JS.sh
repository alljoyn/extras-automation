
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

# Klocwork Analysis for AllJoyn-Javascript on any platform

set -e +x
ci_job=kw-JS.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

source "${CI_COMMON}/${CI_SITE}/cif_kwbuild.sh"

eval _t="${CI_ARTIFACT_NAME}"
export CI_ARTIFACT_NAME=$_t
eval _t="${CIAJ_CORE_GITREV}"
export CIAJ_CORE_GITREV=$_t
eval _t="${CIAJ_SERVICES_GITREV}"
export CIAJ_SERVICES_GITREV=$_t
eval _t="${CIAJ_CORE_SDK_PART}"
export CIAJ_CORE_SDK_PART=$_t
eval _t="${CIAJ_DUKTAPE}"
export CIAJ_DUKTAPE=$_t

export CIAJ_DUKTAPE_ZIP=${CI_SHOPT}/common/${CIAJ_DUKTAPE}.zip
export CIAJ_CORE_SDK_ZIP=${CI_DEPOT}/${CIAJ_CORE_SDK_PART}.zip

ci_ck_found CIAJ_DUKTAPE_ZIP || ci_exit 2 $ci_job, CIAJ_DUKTAPE_ZIP="${CIAJ_DUKTAPE_ZIP}" not found
ci_ck_found CIAJ_CORE_SDK_ZIP || ci_exit 2 $ci_job, CIAJ_CORE_SDK_ZIP="${CIAJ_CORE_SDK_ZIP}" not found

export CIAJ_CORE_SDK=$( basename "${CI_DEPOT}/${CIAJ_CORE_SDK_PART}" )

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

rm -rf "${CI_WORK}/klocwork"
mkdir -p "${CI_WORK}/klocwork/build"
mkdir -p "${CI_WORK}/klocwork/tables"

:
: START kwinject ajtcl
:

pushd alljoyn/core/ajtcl
    ci_kwinject --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
        scons WS=off VARIANT=release ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
popd

if ls -ld alljoyn/services/base_tcl/SConstruct
then
    :
    : START kwinject base_tcl
    :
    pushd alljoyn/services/base_tcl
        ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
            scons WS=off EXCLUDE_ONBOARDING=yes VARIANT=release ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
popd
else
    :
    : WARNING no SConstruct in base_tcl / "${CIAJ_SERVICES_GITREV}"
    :
fi

:
: START kwinject alljoyn-js
:

cd "${WORKSPACE}"
pushd alljoyn/core/alljoyn-js
    case "${GERRIT_BRANCH}" in
    ( RB15.04 ) # before tc_reorg
        if [ "$(uname)" = "Linux" -o "$(uname)" = "Darwin" ]; then
            ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
                scons WS=off VARIANT=release DUKTAPE_DIST="${CI_WORK}/${CIAJ_DUKTAPE}"
        else    # Windows desktop
            (
                export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )
                ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
                    scons WS=off VARIANT=release DUKTAPE_DIST="$( ci_natpath "${CI_WORK}/${CIAJ_DUKTAPE}" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
            )
        fi
        ci_showfs

        :
        : START kwinject console exe
        :
        cd console
        (
            export ALLJOYN_DISTDIR=$( ci_natpath "$ALLJOYN_DISTDIR" )
            ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
                scons WS=off VARIANT=release ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
        )
        ;;
    ( * )       # after tc_reorg
        if [ "$(uname)" = "Linux" -o "$(uname)" = "Darwin" ]; then
            ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
                scons WS=off VARIANT=release DUKTAPE_SRC="${CI_WORK}/${CIAJ_DUKTAPE}/src" ALLJOYN_DIST="$ALLJOYN_DISTDIR"
        else    # Windows desktop
            ci_kwinject --update --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
                scons WS=off VARIANT=release DUKTAPE_SRC="$( ci_natpath "${CI_WORK}/${CIAJ_DUKTAPE}/src" )" ALLJOYN_DIST="$( ci_natpath "$ALLJOYN_DISTDIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
        fi
        ci_showfs
        ;;
    esac
popd

ls -la "${CI_WORK}/klocwork/build"

pushd "${CI_WORK}/klocwork/tables"
    ci_kwbuild ../build/spec.kw || ci_job_xit=$?
    cp build.log "${CI_ARTIFACTS}/klocwork_build.log"
popd

pushd "${CI_WORK}"
    find klocwork \( -type d -name obj -prune \) -o \( -type f -print \) | cpio -pmdu "${CI_ARTIFACTS}"
popd

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
