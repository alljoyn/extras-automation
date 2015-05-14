
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

# Full build for AllJoyn Std Core on all platforms except OSX

set -e +x
ci_job=full-alljoyn_core.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

source "${CI_COMMON}/cif_scons_vartags.sh"
source "${CI_COMMON}/cif_core_sconsbuilds.sh"
source "${CI_COMMON}/cif_core_junits.sh"

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
: sconsbuilds
:
for _variant in debug release
do
    pushd alljoyn/core/alljoyn
        ci_core_sconsbuild "${CIAJ_OS}" "${CIAJ_CPU}" $_variant
    popd
done

:
: ant SDK builds
:
cd "${WORKSPACE}"
case "${CIAJ_OS}" in
( win7 )
    :
    : START SDK
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    ant -f "$( ci_natpath "${CI_COMMON}/build-win7.xml" )" $_verbose -Dscons.cpu="${CIAJ_CPU}" -Dscons.msvc="${CIAJ_MSVC_VERSION%%.*}" \
        -DsdkWork="$( ci_natpath "${CI_ARTIFACTS_SCRATCH}" )" -DsconsDir="$( ci_natpath "${WORKSPACE}/alljoyn/core/alljoyn" )" -DsdkName="${CI_ARTIFACT_NAME}-sdk"
    mv -f "${CI_ARTIFACTS_SCRATCH}/${CI_ARTIFACT_NAME}-sdk.zip" "${CI_ARTIFACTS}"
    ;;
( linux | android )
    for _variant in debug release
    do
        pushd alljoyn/core/alljoyn
            eval $( ci_scons_vartags "${CIAJ_OS}" "${CIAJ_CPU}" $_variant )
        popd
        :
        : START SDK $_variant
        :
        date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
        case "${CIAJ_OS}" in
        ( linux )
            ant -f "${CI_COMMON}/build-linux.xml" $_verbose -Dscons.cpu="${CIAJ_CPU}" -Dscons.variant=$_variant \
                -DsdkWork="${CI_ARTIFACTS_SCRATCH}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk-$vartag"
            ;;
        ( android )
            ant -f "${CI_COMMON}/build-android.xml" $_verbose -Dscons.cpu="${CIAJ_CPU}" -Dscons.variant=$_variant \
                -DANDROID_SDK="${ANDROID_SDK}" -DANDROID_NDK="${ANDROID_NDK}" -DANDROID_SRC="${ANDROID_SRC}" \
                -DALLJOYN_KEYSTORE.keystore="${ALLJOYN_ANDROID_KEYSTORE}" -DALLJOYN_KEYSTORE.password="${ALLJOYN_ANDROID_KEYSTORE_PW}"  -DALLJOYN_KEYSTORE.alias="${ALLJOYN_ANDROID_KEYSTORE_ALIAS}" \
                -DsdkWork="${CI_ARTIFACTS_SCRATCH}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk-$vartag"
            ;;
        esac
        mv -f "${CI_ARTIFACTS_SCRATCH}/${CI_ARTIFACT_NAME}-sdk-$vartag.zip" "${CI_ARTIFACTS}"
    done
    ;;
( android )
    : INFO android SDK : NOT YET
    ;;
esac

:
: START dist and test zips
:
for _variant in debug release
do
    pushd alljoyn/core/alljoyn
        eval $( ci_scons_vartags "${CIAJ_OS}" "${CIAJ_CPU}" $_variant )

        :
        : dist.zip $_variant
        :
        ci_zip_simple_artifact "$dist" "${CI_ARTIFACT_NAME}-dist-$vartag"

        case "${CIAJ_BINDINGS}" in
        ( java,* | *,java,* | *,java )
            :
            : test.zip $_variant
            :
            ci_core_ready_junits "${CIAJ_OS}" "${CIAJ_CPU}" $_variant
            ci_zip_simple_artifact "$test" "${CI_ARTIFACT_NAME}-test-$vartag"
            ;;
        ( * )
            case "${CIAJ_GTEST}" in
            ( [NnFf]* )
                :
                : WARNING $ci_job, no test zips produced CIAJ_GTEST="${CIAJ_GTEST}" and CIAJ_BINDINGS="${CIAJ_BINDINGS}"
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
            ;;
        esac
    popd
done

for _variant in debug release
do
    # cram some stuff into this do loop just so we can easily "break" if anything goes wrong
    # never fail this build just because test_tools does not work - instead, mark UNSTABLE

    :
    : START test_tools $_variant
    :

    pushd alljoyn/core/alljoyn
        eval $( ci_scons_vartags "${CIAJ_OS}" "${CIAJ_CPU}" $_variant )
            # per request, test_tools team, 5/14/2015 - nothing follows test_tools in the build anyway
        rm -f "$dist"/cpp/lib/liballjoyn*.so
    popd
    pushd alljoyn/core

        # check out core/test.git, aka "test_tools"
        case "${GIT_URL}" in
        ( */core/alljoyn.git )   b=${GIT_URL%/core/alljoyn.git} ;;
        ( */core/alljoyn )       b=${GIT_URL%/core/alljoyn} ;;
        ( * )   ci_exit 2 $ci_job, trap "GIT_URL=${GIT_URL}" ;;
        esac

        rm -rf test_tools ajtcl
        git clone "$b/core/test.git" test_tools && \
        git clone "$b/core/ajtcl.git"           || {
            :
            : UNSTABLE $ci_job, test_tools
            :
            popd
            break
        }
        # always take master branch

        # manifest for test_tools artifact
        cat ../manifest.txt       > test_tools/scl/manifest.txt
        ci_genversion test_tools >> test_tools/scl/manifest.txt

        # build scl subdirectory only
        pushd test_tools/scl
            :
            : INFO test_tools manifest
            :
            cat manifest.txt
            :
            git log -1
            ci_showfs

            ls SConstruct > /dev/null || {
                :
                : UNSTABLE $ci_job, test_tools
                :
                popd ; popd
                break
            }

            :
            : build test_tools $_variant
            :
            ci_core_test_sconsbuild "${CIAJ_OS}" "${CIAJ_CPU}" $_variant || {
                :
                : UNSTABLE $ci_job, test_tools $_variant
                :
                popd ; popd
                break
            }
            ci_showfs

            :
            : test_tools.zip $_variant
            :
            ci_zip_simple_artifact "$PWD" "${CI_ARTIFACT_NAME}-tools-$vartag" || {
                :
                : UNSTABLE $ci_job, test_tools $_variant
                :
                popd ; popd
                break
            }
        popd
    popd
done

:
:
set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
