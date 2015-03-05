
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

# Full build for AllJoyn Core (Std) on OSX
# OSX build uses xcodebuild, not scons, so this build script is different than the other platforms

set -e +x
ci_job=full-alljoyn_core-osx.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

# number of parallel build processes (scons only) = number_of_processors / 2, but no less than 2
_j=$( expr $NUMBER_OF_PROCESSORS / 2 )
case "$_j" in ( "" | 0 | 1 ) _j=2 ;; esac
export SCONSFLAGS="-j $_j"

source "${CI_COMMON}/cif_core_xcodebuilds.sh"
source "${CI_COMMON}/cif_core_gtests.sh"

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) verbose="" ;; ( * ) verbose=-verbose; ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

: START job

:
: xcodebuilds for google tests and iphone simulator on Mac - Debug only
:
pushd alljoyn/core/alljoyn
    ci_xcodebuild_simulator debug
popd
    : save clean workspace
rm  -f  "${CI_SCRATCH}/xcodebuild-simulator-debug.tar"
tar -cf "${CI_SCRATCH}/xcodebuild-simulator-debug.tar" alljoyn/core/alljoyn

: google tests

pushd alljoyn/core/alljoyn
    ci_core_gtests darwin x86 debug || ci_job_xit=$?
popd

## pushd alljoyn/core/alljoyn/alljoyn_obj/AllJoynFramework_iOS
## xcodebuild -project AllJoynFramework_iOS.xcodeproj -scheme AllJoynFramework_iOS -sdk iphonesimulator -configuration $configuration test TEST_AFTER_BUILD=YES ## FIXME not with XCode 6

    : restore clean workspace
rm -rf  alljoyn/core/alljoyn
tar -xf "${CI_SCRATCH}/xcodebuild-simulator-debug.tar"
rm  -f  "${CI_SCRATCH}/xcodebuild-simulator-debug.tar"

:
: xcodebuilds for google tests and iphone simulator on Mac - Release
:
pushd alljoyn/core/alljoyn
    ci_xcodebuild_simulator release
popd
    : save clean workspace
rm  -f  "${CI_SCRATCH}/xcodebuild-simulator-release.tar"
tar -cf "${CI_SCRATCH}/xcodebuild-simulator-release.tar" alljoyn/core/alljoyn

: google tests

pushd alljoyn/core/alljoyn
    ci_core_gtests darwin x86 release || ci_job_xit=$?
popd

    : restore clean workspace
rm -rf  alljoyn/core/alljoyn
tar -xf "${CI_SCRATCH}/xcodebuild-simulator-release.tar"
rm  -f  "${CI_SCRATCH}/xcodebuild-simulator-release.tar"

:
: all remaining xcodebuilds
:
pushd alljoyn/core/alljoyn
    ci_xcodebuild_arm debug
    ci_xcodebuild_arm release
popd

:
: START SDK
:
cd "${WORKSPACE}"
ant -f "${CI_COMMON}/build-mac.xml" $verbose -DsdkWork="${CI_ARTIFACTS_WORK}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk"
mv -f "${CI_ARTIFACTS_WORK}/${CI_ARTIFACT_NAME}-sdk.zip" "${CI_ARTIFACTS}"

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
