
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# Gerrit-verify build for AllJoyn Thin Core on any platform

    # FIXME 2015-02-05: Linux build should load up a daemon router,
    #       but the BusAttach test case was disabled in buildbot for some reason,
    #       so we do not need a daemon yet, so that code is deactivated

set -e +x
ci_job=vfy-TC.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

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

ci_genversion alljoyn/core/ajtcl ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

:
: START scons ajtcl rel
:

rm -f "${CI_SCRATCH}/ajtcl.tar"
tar -cf "${CI_SCRATCH}/ajtcl.tar" alljoyn/core/ajtcl

pushd alljoyn/core/ajtcl
    ci_scons V=$_verbose WS=$_ws VARIANT=release GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs

    :
    : START doxygen rel
    :
    doxygen
popd

cd "${WORKSPACE}"

ci_zip_simple_artifact alljoyn "${CI_ARTIFACT_NAME}-rel"

# reminder - ajtcl scons only builds ajtcltest if variant=debug

:
: START scons ajtcl dbg
:

rm -rf alljoyn/core/ajtcl
tar -xf "${CI_SCRATCH}/ajtcl.tar"

pushd alljoyn/core/ajtcl
    ci_scons V=$_verbose WS=off VARIANT=debug   GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs

    :
    : START doxygen dbg
    :
    doxygen
popd

cd "${WORKSPACE}"

ci_zip_simple_artifact alljoyn "${CI_ARTIFACT_NAME}-dbg"

:
: START ajtcltest dbg
:

    # FIXME : tests should be run in a separate "test" build
    # FIXME : tests should run a stand-alone alljoyn-daemon (Linux) or sample router (Windows), but they don't do either

source "${CI_COMMON}/cif_scons_vartags.sh"
source "${CI_COMMON}/cif_core_gtests.sh"

pushd alljoyn/core/ajtcl
    eval $( ci_thin_scons_vartags debug )
    ci_core_gtests $_os $_cpu debug on ajtcl
popd

set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"