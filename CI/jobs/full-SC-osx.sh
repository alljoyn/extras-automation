
# Copyright (c) 2016 Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright 2016 Open Connectivity Foundation and Contributors to
#    AllSeen Alliance. All rights reserved.
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

# Full build for AllJoyn Std Core on OSX
# OSX build uses xcodebuild, not scons, so this build script is different than the other platforms

set -e +x
ci_job=full-SC-osx.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

# number of parallel build processes (scons only) = number_of_processors / 2, but no less than 2
_j=$( expr $NUMBER_OF_PROCESSORS / 2 )
case "$_j" in ( "" | 0 | 1 ) _j=2 ;; esac
export SCONSFLAGS="-j $_j"
# scons keepgoing flag
### FIXME : ignore CI_KEEPGOING, do not use scons -k in AJ SC build for OS/X
### case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) ;; ( * ) SCONSFLAGS="-k $SCONSFLAGS" ;; esac

source "${CI_COMMON}/cif_core_xcodebuilds.sh"
source "${CI_COMMON}/cif_scons_vartags.sh"

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose= ;; ( * ) _verbose=-verbose ; ci_showfs ;; esac
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

:
: INFO manifest
:

cat alljoyn/manifest.txt

:
: xcodebuilds
:
for _variant in debug release
do
    pushd alljoyn/core/alljoyn
        ci_xcodebuild_simulator $_variant
        ci_xcodebuild_arm $_variant
    popd
done

:
: START SDK
:
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
cd "${WORKSPACE}"
ant -f "${CI_COMMON}/build-mac.xml" $_verbose -DsdkWork="${CI_SCRATCH_ARTIFACTS}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk"
mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk.zip" "${CI_ARTIFACTS}"
mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk.txt" "${CI_ARTIFACTS}"
tocfilename_ref=$( echo "${CI_ARTIFACT_NAME}-sdk-ref" | sed -e 's,-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][a-zA-Z0-9.]*-,-0.0.0-,' )
cp "alljoyn/core/alljoyn/alljoyn_core/docs/sdktoc/$tocfilename_ref.txt" "${CI_ARTIFACTS}" || : ok

:
: START dist and test zips
:
for _variant in debug release
do
    pushd alljoyn/core/alljoyn
        eval $( ci_scons_vartags darwin x86 $_variant )
        :
        : dist.zip $_variant
        :
        ci_zip_simple_artifact "$dist" "${CI_ARTIFACT_NAME}-dist-$vartag"

        case "${CIAJ_GTEST}" in
        ( [NnFf]* )
            :
            : WARNING $ci_job, no test zips produced because CIAJ_GTEST="${CIAJ_GTEST}"
            :
            popd
            break
            ;;
        ( * )
            :
            : test.zip $_variant
            :
            ci_zip_simple_artifact "$test" "${CI_ARTIFACT_NAME}-test-$vartag"
            ;;
        esac
    popd
done

:
:
set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"