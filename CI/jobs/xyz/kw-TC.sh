
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# Klocwork Analysis for AllJoyn Thin Core on any Xyzcity platform

set -e +x
ci_job=xyz/kw-TC.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

source "${CI_COMMON}/${CI_SITE}/cif_kwbuild.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/ajtcl ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

:
: START kwinject
:
rm -rf "${CI_WORK}/klocwork"
mkdir -p "${CI_WORK}/klocwork/build"
mkdir -p "${CI_WORK}/klocwork/tables"

pushd alljoyn/core/ajtcl
    ci_kwinject --ignore-files 'conftest*.*' --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
        scons WS=off VARIANT=debug \
        GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" \
        ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs
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