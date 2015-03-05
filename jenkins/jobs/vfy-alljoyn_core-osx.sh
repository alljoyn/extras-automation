
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

# Gerrit-verify build for AllJoyn Core (Std) on OSX
# OSX build uses xcodebuild, not scons, so this build script is different than the other platforms

set -e +x
ci_job=vfy-alljoyn_core-osx.sh
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
case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
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
: xcodebuilds for google tests and iphone simulator on Mac - "${CIAJ_VARIANT}" only
:

pushd alljoyn/core/alljoyn
    ci_xcodebuild_simulator "${CIAJ_VARIANT}"
popd

: google tests

pushd alljoyn/core/alljoyn
    ci_core_gtests darwin x86 "${CIAJ_VARIANT}" || ci_job_xit=$?
popd

## pushd alljoyn/core/alljoyn/alljoyn_obj/AllJoynFramework_iOS
## xcodebuild -project AllJoynFramework_iOS.xcodeproj -scheme AllJoynFramework_iOS -sdk iphonesimulator -configuration $configuration test TEST_AFTER_BUILD=YES ## FIXME not with XCode 6

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
