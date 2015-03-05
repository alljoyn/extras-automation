
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

# Gerrit-verify build for AllJoyn Core (Std) on all platforms except OSX

set -e +x
ci_job=vfy-alljoyn_core.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CIAJ_VARIANT}" in
( debug )   export vartag=dbg ;;
( release ) export vartag=rel ;;
( * )       ci_exit 2 $ci_job, "CIAJ_VARIANT=${CIAJ_VARIANT}" ;;
esac

case "${CIAJ_CPU}" in
( *64 )     export cputag=x64 ;;
( *86 )     export cputag=x86 ;;
( arm* )    export cputag=${CIAJ_CPU} ;;
( * )       ci_exit 2 $ci_job, "CIAJ_CPU=${CIAJ_CPU}" ;;
esac

case "${CIAJ_BINDINGS}" in
( js,* | *,js,* | *,js )
    export GECKO_BASE=$( ci_natpath "${GECKO_BASE}" )
    export JSDOC_DIR=$( ci_natpath "${JSDOC_DIR}" )
    ;;
( * )
    unset GECKO_BASE
    unset JSDOC_DIR
    ;;
esac

case "${CIAJ_GTEST}" in
( [NnFf]* ) unset GTEST_DIR ;;
( * )       export GTEST_DIR=$( ci_natpath "${GTEST_DIR}" ) ;;
esac

export dist=${WORKSPACE}/alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/${CIAJ_VARIANT}/dist
export test=${WORKSPACE}/alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/${CIAJ_VARIANT}/test

case "${CIAJ_OS}" in
( linux | win7 )
    source "${CI_COMMON}/cif_core_gtests.sh"
    source "${CI_COMMON}/cif_core_junits.sh"
    ;;
( android )
    : android unit tests : NOT YET
    ;;
esac

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) verbose=0 ;; ( * ) verbose=1 ; ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

:
: START SCons
:

pushd alljoyn/core/alljoyn
    ci_scons -j "$NUMBER_OF_PROCESSORS" OS="${CIAJ_OS}" CPU="${CIAJ_CPU}" VARIANT="${CIAJ_VARIANT}" BINDINGS="${CIAJ_BINDINGS}" \
        BR="${CIAJ_BR}" POLICYDB="${CIAJ_POLICYDB}" \
        ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}"${CIAJ_MSVC_VERSION}" \
        ${CIAJ_ANDROID_API_LEVEL:+ANDROID_API_LEVEL=}"${CIAJ_ANDROID_API_LEVEL}" \
        ${GECKO_BASE:+GECKO_BASE=}"$GECKO_BASE" \
        ${JSDOC_DIR:+JSDOC_DIR=}"$JSDOC_DIR" \
        ${GTEST_DIR:+GTEST_DIR=}"$GTEST_DIR" \
        ${ANDROID_SDK:+ANDROID_SDK=}"$ANDROID_SDK" \
        ${ANDROID_NDK:+ANDROID_NDK=}"$ANDROID_NDK" \
        ${ANDROID_SRC:+ANDROID_SRC=}"$ANDROID_SRC" \
        V=$verbose WS=off DOCS=html
    ci_showfs
popd

ci_showfs "$dist"
ci_showfs "$test"

case FIXME in
( notYet )
:
: START artifacts
:

cd "${WORKSPACE}"
ci_zip_simple_artifact "$dist" "${CI_ARTIFACT_NAME}-dist-${CIAJ_OS}-$cputag-$vartag"
ci_zip_simple_artifact "$test" "${CI_ARTIFACT_NAME}-test-${CIAJ_OS}-$cputag-$vartag"
;;
esac

case "${CIAJ_OS}" in
( linux | win7 )
    : google tests

    pushd alljoyn/core/alljoyn
        ci_core_gtests "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}" "${CIAJ_BR}" "${CIAJ_BINDINGS}"
    popd

    : junit tests
    pushd alljoyn/core/alljoyn
        ci_core_junits "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}" "${CIAJ_BR}"
    popd
    ;;
( android )
    : INFO android unit tests : NOT YET
    ;;
esac

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
