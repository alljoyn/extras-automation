
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# "Sandbox" build for prototyping Jenkins builds within the AllJoyn CI framework. 
# Cloned from vfy-TC-u1404 and stripped-down.

set -e +x
ci_job=sandbox.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose=0 ;; ( * ) _verbose=1 ;; esac

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/ajtcl ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

:
: START scons ajtcl dbg
:

rm -f   "${CI_SCRATCH}/ajtcl.tar"
tar -cf "${CI_SCRATCH}/ajtcl.tar" alljoyn/core/ajtcl

pushd alljoyn/core/ajtcl
    ci_scons V=$_verbose WS=off VARIANT=debug GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
popd

:
: START artifact
:

cd "${WORKSPACE}"

ci_zip_simple_artifact alljoyn "${CI_ARTIFACT_NAME}-dbg"

set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"