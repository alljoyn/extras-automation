
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
ci_job=full-SC.sh
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
( win7 | win10 )
    :
    : START SDK
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    ant -f "$( ci_natpath "${CI_COMMON}/build-win7.xml" )" $_verbose -Dscons.os="${CIAJ_OS}" -Dscons.cpu="${CIAJ_CPU}" -Dscons.msvc="${CIAJ_MSVC_VERSION%%.*}" \
        -DsdkWork="$( ci_natpath "${CI_SCRATCH_ARTIFACTS}" )" -DsconsDir="$( ci_natpath "${WORKSPACE}/alljoyn/core/alljoyn" )" -DsdkName="${CI_ARTIFACT_NAME}-sdk"
    mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk.zip" "${CI_ARTIFACTS}"
    mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk.txt" "${CI_ARTIFACTS}"
    tocfilename_ref=$( echo "${CI_ARTIFACT_NAME}-sdk-ref" | sed -e 's,-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][a-zA-Z0-9.]*-,-0.0.0-,' )
    cp "alljoyn/core/alljoyn/alljoyn_core/docs/sdktoc/$tocfilename_ref.txt" "${CI_ARTIFACTS}" || : ok
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
                -DsdkWork="${CI_SCRATCH_ARTIFACTS}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk-$vartag"
            ;;
        ( android )
            case "${GERRIT_BRANCH}" in
            ( RB15.04 | RB14.* )
                # backward compatibility between build-android.xml (CI config) and Android.mk (src)
                sdk_crypto=openssl
                ;;
            ( * )
                sdk_crypto="${CIAJ_CRYPTO}"
                ;;
            esac
            ant -f "${CI_COMMON}/build-android.xml" $_verbose -Dscons.cpu="${CIAJ_CPU}" -Dscons.variant=$_variant \
                -DANDROID_SDK="${ANDROID_SDK}" -DANDROID_NDK="${ANDROID_NDK}" -DANDROID_SRC="${ANDROID_SRC}" -Dscons.crypto="$sdk_crypto" \
                -DALLJOYN_KEYSTORE.keystore="${ALLJOYN_ANDROID_KEYSTORE}" -DALLJOYN_KEYSTORE.password="${ALLJOYN_ANDROID_KEYSTORE_PW}"  -DALLJOYN_KEYSTORE.alias="${ALLJOYN_ANDROID_KEYSTORE_ALIAS}" \
                -DsdkWork="${CI_SCRATCH_ARTIFACTS}" -DsconsDir="${WORKSPACE}/alljoyn/core/alljoyn" -DsdkName="${CI_ARTIFACT_NAME}-sdk-$vartag"
            ;;
        esac
        mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk-$vartag.zip" "${CI_ARTIFACTS}"
        mv -f "${CI_SCRATCH_ARTIFACTS}/${CI_ARTIFACT_NAME}-sdk-$vartag.txt" "${CI_ARTIFACTS}"
        tocfilename_ref=$( echo "${CI_ARTIFACT_NAME}-sdk-$vartag-ref" | sed -e 's,-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][a-zA-Z0-9.]*-,-0.0.0-,' )
        cp "alljoyn/core/alljoyn/alljoyn_core/docs/sdktoc/$tocfilename_ref.txt" "${CI_ARTIFACTS}" || : ok
    done
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
            ci_core_ready_junits "${CIAJ_OS}" "${CIAJ_CPU}" "$_variant" "${CIAJ_BINDINGS}"
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

case "${CIAJ_OS}" in ( android )
    :
    : WARNING skipping core/test_tools because this is android
    :
    set +x
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    echo >&2 + : STATUS $ci_job exit $ci_job_xit
    exit "$ci_job_xit"
    ;;
esac

case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose=0 ;; ( * ) _verbose=1 ;; esac

case "${CIAJ_GTEST}" in
( [NnFf]* ) _local_gtest_dir= ;;
( * )       _local_gtest_dir=$( ci_natpath "${GTEST_DIR}" ) ;;
esac

for _variant in debug release
do
    # cram some stuff into this do loop just so we can easily "break" if anything goes wrong
    # never fail this build just because core/test build does not work - instead, mark UNSTABLE

    :
    : START core/test tools $_variant
    :

    pushd alljoyn/core/alljoyn
        eval $( ci_scons_vartags "${CIAJ_OS}" "${CIAJ_CPU}" $_variant )
            # per request, core/test team, 5/14/2015 - nothing follows core/test in the build anyway
        rm -f "$dist"/cpp/lib/liballjoyn*.so
    popd

    pushd alljoyn/core

        case "${GIT_URL}" in
        ( */core/alljoyn.git )  b=${GIT_URL%/core/alljoyn.git} ;;
        ( */core/alljoyn )      b=${GIT_URL%/core/alljoyn} ;;
        ( * )   ci_exit 2 $ci_job, trap "GIT_URL=${GIT_URL}" ;;
        esac

        # check out core/test.git, aka "tools"
        # always master branch
        rm -rf test
        git clone "$b/core/test.git"    || {
            :
            : UNSTABLE $ci_job, core/test tools
            :
            popd
            break
        }

        # manifest for core/test "tools" artifact
        cat ../manifest.txt >   test/scl/manifest.txt
        ci_genversion test  >>  test/scl/manifest.txt

        # check out core/ajtcl
        rm -rf ajtcl
        case "${CIAJ_OS}" in
        ( android )
            ;;
        ( * )
            git clone "$b/core/ajtcl.git"   || {
                :
                : UNSTABLE $ci_job, core/test tools
                :
                popd
                break
            }
            pushd ajtcl
                # try to get same branch as Std Core build used
                git checkout "${GERRIT_BRANCH}" || {
                    :
                    : WARNING, $ci_job, GERRIT_BRANCH=${GERRIT_BRANCH} not found in ajtcl
                    : using default branch:
                    git branch
                    :
                }
            popd

            # manifest for core/test "tools" artifact
            ci_genversion ajtcl >>  test/scl/manifest.txt
            ;;
        esac

        :
        : INFO core/test tools manifest
        :
        cat test/scl/manifest.txt
        :

        # build ajtcl
        case "${CIAJ_OS}" in
        ( android )
            ;;
        ( * )
            pushd ajtcl
                :
                : INFO scons build ajtcl $_variant
                :
                git log -1
                ci_showfs

                : START scons build ajtcl $_variant
                ci_scons V=$_verbose WS=off VARIANT=$_variant ${_local_gtest_dir:+GTEST_DIR=}"$_local_gtest_dir" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION} || {
                    :
                    : WARNING $ci_job, scons build failed ajtcl $_variant
                    :
                }
                # per request, core/test team, 7/23/2015
                rm -f libajtcl*.so dist/lib/libajtcl*.so
            popd
            ;;
        esac

        # build core/test, scl subdirectory only
        pushd test/scl
            :
            : INFO scons build core/test/scl $_variant
            :
            git log -1
            ci_showfs

            ls SConstruct > /dev/null || {
                :
                : UNSTABLE $ci_job, core/test/scl $_variant
                :
                popd ; popd
                break
            }

            ci_core_test_sconsbuild "${CIAJ_OS}" "${CIAJ_CPU}" $_variant || {
                :
                : UNSTABLE $ci_job, core/test/scl $_variant
                :
                popd ; popd
                break
            }
            ci_showfs

            :
            : core/test tools.zip $_variant
            :
            ci_zip_simple_artifact "$PWD" "${CI_ARTIFACT_NAME}-tools-$vartag" || {
                :
                : UNSTABLE $ci_job, core/test tools $_variant
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
