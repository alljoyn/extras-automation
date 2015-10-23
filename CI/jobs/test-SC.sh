
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

# Test (downstream) build for AllJoyn Std Core on all platforms except OSX

set -e +x
ci_job=test-SC.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CI_UP1}" in ( "" ) ci_exit 2 $ci_job, no upstream job artifacts found ;; esac

case "${CIAJ_OS}" in
( linux | win7 | win10 )
    source "${CI_COMMON}/cif_core_gtests.sh"
    source "${CI_COMMON}/cif_core_junits.sh"
    ;;
( darwin )
    source "${CI_COMMON}/cif_core_gtests.sh"
    ;;
( android )
    : android no-op
    ;;
esac

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose= ;; ( * ) _verbose=-verbose ; ci_showfs ;; esac
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

:
: START get upstream artifacts
:
rm -rf alljoyn/core/alljoyn/build

up1_zips=$( cd "${CI_UP1}" && ls -d "${CI_ARTIFACT_NAME_UP1}"*.zip | grep -E -- '-(dist|test)-(dbg|rel)\.zip' )
case "$up1_zips" in ( "" ) ci_exit 2 $ci_job, upstream 1 artifact "${CI_ARTIFACT_NAME_UP1}*-(dist,test)-(dbg,rel).zip" not found ;; esac

_variants=""
for up1_zip in $up1_zips
do
    up1_dir=${up1_zip%.zip}
    case "$up1_dir" in
    ( *-dist-dbg ) ziptag=dist ; vartag=dbg ; _variant=debug ;;
    ( *-dist-rel ) ziptag=dist ; vartag=rel ; _variant=release ;;
    ( *-test-dbg ) ziptag=test ; vartag=dbg ; _variant=debug ;;
    ( *-test-rel ) ziptag=test ; vartag=rel ; _variant=release ;;
    ( * ) : WARNING upstream 1 artifact "$up1_zip" not recognized ; continue ;;
    esac
    case "$_variants" in ( *${_variant}* ) ;; ( * ) _variants="$_variants $_variant" ;; esac
    :
    : INFO $up1_zip
    :
    ls -d          alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/$_variant/$ziptag 2> /dev/null && ci_exit 2 $ci_job, multiple upstream artifacts "*-$ziptag-$vartag.zip"
    mkdir -p       alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/$_variant 2> /dev/null || : ok
    ci_unzip "${CI_UP1}/$up1_zip"
    ci_mv $up1_dir alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/$_variant/$ziptag
    ci_showfs      alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/$_variant/$ziptag
done

ci_ckSdkToc() {

    # skip Sdk Toc test for builds where the appropriate reference Toc file is not known
    # to be checked-into alljoyn.git/alljoyn_core/docs/sdktoc

    case "${GERRIT_BRANCH}" in
    ( RB14.* | RB15.04 )
        :
        : INFO skipping ck SDK TOC, branch is ${GERRIT_BRANCH}
        :
        return 0
        ;;
    esac
    case "${CIAJ_OS}/${CIAJ_MSVC_VERSION}" in
    ( win7/12.* | win10/14.* )
        # continue
        ;;
    ( win7/* | win10/* )
        :
        : INFO skipping ck SDK TOC, MSVC_VERSION is "${CIAJ_MSVC_VERSION}"
        :
        return 0
        ;;
    esac
    case "${CIAJ_OS}/${CIAJ_CPU}" in
    ( darwin/*86 )
        # continue
        ;;
    ( *86 )
        :
        : INFO skipping ck SDK TOC, CPU is "${CIAJ_CPU}"
        :
        return 0
        ;;
    esac

    :
    : START ck SDK TOC
    :
    if ls -l "${CI_UP1}/$tocfilename_ref.txt" ; then
        cp "${CI_UP1}/$tocfilename_ref.txt" "${CI_ARTIFACTS}"
        if ls -l "${CI_UP1}/$tocfilename_new.txt" ; then
            cp "${CI_UP1}/$tocfilename_new.txt" "${CI_ARTIFACTS}"
            ant -f "$( ci_natpath "${CI_COMMON}/build-toc.xml" )" $_verbose "-Dscons.br=${CIAJ_BR}" \
                "-Dtocfile.ref=$( ci_natpath "${CI_ARTIFACTS}/$tocfilename_ref.txt" )" \
                "-Dtocfile.new=$( ci_natpath "${CI_ARTIFACTS}/$tocfilename_new.txt" )" || {
                :
                : ERROR SDK TOC "$tocfilename_new.txt" changed
                :
                return 2
            }
        else
            :
            : ERROR SDK TOC "$tocfilename_new.txt" file not found
            :
            return 2
        fi
    else
        :
        : ERROR SDK TOC "$tocfilename_ref.txt" file not found
        :
        return 2
    fi
    return 0
}

cd "${WORKSPACE}"
case "${CIAJ_OS}" in
( darwin | win7 | win10 )
    tocfilename_ref=$( echo "${CI_ARTIFACT_NAME_UP1}-sdk-ref" | sed -e 's,-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][a-zA-Z0-9.]*-,-0.0.0-,' )
    tocfilename_new=${CI_ARTIFACT_NAME_UP1}-sdk
    ci_ckSdkToc || {
        ci_job_xit=$?
    }
    ;;
( android | linux )
    for _vartag in dbg rel
    do
        tocfilename_ref=$( echo "${CI_ARTIFACT_NAME_UP1}-sdk-$_vartag-ref" | sed -e 's,-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][a-zA-Z0-9.]*-,-0.0.0-,' )
        tocfilename_new=${CI_ARTIFACT_NAME_UP1}-sdk-$_vartag
        ci_ckSdkToc || {
            ci_job_xit=$?
            case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) break ;; esac
        }
    done
    ;;
esac

# keep going or exit now?

case $ci_job_xit in
( 0 )
    ;;
( * )
    case "${CI_KEEPGOING}" in
    ( "" | [NnFf]* )
        :
        :
        set +x
        date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
        echo >&2 + : STATUS $ci_job exit $ci_job_xit
        exit "$ci_job_xit"
        ;;
    esac
    ;;
esac

case "${CIAJ_OS}" in
( android )
    :
    : INFO android unit tests not implemented yet
    :
    set +x
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    echo >&2 + : STATUS $ci_job exit $ci_job_xit
    exit "$ci_job_xit"
    ;;
esac

for _variant in $_variants
do
    case $_variant in ( debug ) vartag=dbg ;; ( release ) vartag=rel ;; ( * ) ci_exit 2 $ci_job error trap ;; esac
    for ziptag in dist test
    do
        ls -ld     alljoyn/core/alljoyn/build/${CIAJ_OS}/${CIAJ_CPU}/$_variant/$ziptag > /dev/null  || ci_exit 2 $ci_job, missing upstream artifact "*-$ziptag-$vartag.zip"
    done
    case "${CIAJ_OS}" in
    ( linux | win7 | win10 )
        pushd alljoyn/core/alljoyn
            :
            : google tests $vartag
            :
            ci_core_gtests "${CIAJ_OS}" "${CIAJ_CPU}" $_variant "${CIAJ_BR}" "${CIAJ_BINDINGS}" || {
                ci_job_xit=2
                case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) popd ; break ;; esac
            }

            :
            : junit tests $vartag
            :
            ci_core_junits "${CIAJ_OS}" "${CIAJ_CPU}" $_variant "${CIAJ_BR}" "${CIAJ_BINDINGS}" || {
                ci_job_xit=2
                case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) popd ; break ;; esac
            }

            case "${CIAJ_OS}" in
            ( linux )
                :
                : START make samples $vartag
                :
                coresamples="build/${CIAJ_OS}/${CIAJ_CPU}/$_variant/dist/cpp/samples"
                ls -la "$coresamples"
                list=$( find "$coresamples" -type f -name Makefile | sort )

                echo "$list" | while read i
                do
                    case "$i" in ( "" ) continue ;; esac
                    d=$( dirname "$i" )
                    pushd "$d"
                        :
                        : INFO $d
                        :
                        ls -la
                        make || {
                            ci_job_xit=$?
                            case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) popd ; break ;; esac
                        }
                    popd
                done
                case $ci_job_xit in ( 0 ) ;; ( * ) case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) popd ; break ;; esac ;; esac
                ;;
            esac
        popd
        ;;
    ( darwin )
        :
        : google tests $vartag
        :
        pushd alljoyn/core/alljoyn
            ci_core_gtests "${CIAJ_OS}" "${CIAJ_CPU}" $_variant "${CIAJ_BR}" "${CIAJ_BINDINGS}" || {
                ci_job_xit=2
                case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) popd ; break ;; esac
            }
        popd

    ##  pushd alljoyn/core/alljoyn/alljoyn_objc/AllJoynFramework_iOS
    ##      :
    ##      : xcode simulator test SKIPPED
    ##      :
    ##  FIXME for two reasons:
    ##  1. xcode simulator does not work with XCode 6, says Ry, unless someone is logged-in to the Console
    ##  2. the following commandline only works if the preceding xcodebuilds were run w -configuration Release - ie, if Release bits were built
    ##      xcodebuild -project AllJoynFramework_iOS.xcodeproj -scheme AllJoynFramework_iOS -sdk iphonesimulator -configuration $configuration test TEST_AFTER_BUILD=YES \
    ##          -derivedDataPath "${CI_WORK}/DerivedData/AllJoynFramework_iOS-iphonesimulator"
    ##  popd
        ;;
    ( android )
        :
        : INFO android unit tests : NOT YET
        :
        ;;
    esac
done
:
:
set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
