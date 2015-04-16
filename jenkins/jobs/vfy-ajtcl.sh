
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

# Gerrit-verify build for AllJoyn Core TC on any platform

    # FIXME 2015-02-05: Linux build should load up a daemon router,
    #       but the BusAttach test case was disabled in buildbot for some reason,
    #       so we do not need a daemon yet, so that code is deactivated

set -e +x
ci_job=vfy-ajtcl.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

case "$( uname )" in
( Linux )
    _uncrustify=$( uncrustify --version ) || : ok
    case "$_uncrustify" in
    ( uncrustify* )
        case "${GERRIT_BRANCH}/$_uncrustify" in
        ( RB14.12/uncrustify\ 0.61* )
            _ws=off
            :
            : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
            :
            ;;
        ( RB14.12/uncrustify\ 0.57* )
            _ws=detail
            ;;
        ( */uncrustify\ 0.61* )
            _ws=detail
            ;;
        ( * )
            _ws=off
            :
            : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
            :
            ;;
        esac
        ;;
    ( * )
        _ws=off
        :
        : WARNING $ci_job, uncrustify not found: skipping Whitespace scan
        :
        ;;
    esac
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
    ci_scons WS=$_ws VARIANT=release GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs

    :
    : START doxygen rel
    :
    doxygen
popd

cd "${WORKSPACE}"

ci_zip_simple_artifact alljoyn "${CI_ARTIFACT_NAME}-rel"

:
: START scons ajtcl dbg
:

rm -rf alljoyn/core/ajtcl
tar -xf "${CI_SCRATCH}/ajtcl.tar"

pushd alljoyn/core/ajtcl
    ci_scons WS=off VARIANT=debug   GTEST_DIR="$( ci_natpath "$GTEST_DIR" )" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
    ci_showfs

    :
    : START doxygen dbg
    :
    doxygen
popd

cd "${WORKSPACE}"

ci_zip_simple_artifact alljoyn "${CI_ARTIFACT_NAME}-dbg"

: check for ajtcltest exe

if ls -ldL alljoyn/core/ajtcl/unit_test/ajtcltest ; then
    : ajtcltest ok
elif ls -ldL alljoyn/core/ajtcl/unit_test/ajtcltest.exe ; then
    : ajtcltest.exe ok
else
    case "$( uname )" in
    ( Darwin )
        :
        : WARNING $ci_job, "ajtcltest exe not found"
        : "scons does not build it on OS X?"
        :
        ;;
    ( * )
        :
        : ERROR $ci_job, "ajtcltest exe not found"
        :
        ci_job_xit=2
        ;;
    esac
    set +x
    echo >&2 + : STATUS $ci_job exit $ci_job_xit
    exit "$ci_job_xit"
fi

case "${CI_SHELL_W}" in
( "" )
    case "$( uname )" in

        # FIXME 2015-02-05: start

    ( Linux )
        ulimit -c unlimited
        ;;
    ( Linux-FIXME )         # linux - run alljoyn-daemon
        start_daemon=-s

        # FIXME 2015-02-05: this dead code would work if reactivated for some reason
        #           it should all be replaced when we know what Jenkin Core (Std) builds are going to do for "testbot"

        # until we have real Core Std SDK's built in Jenkins, just mimic what we did in buildbot 8040 - ie, depend on buildbot 8010

        :
        : START find a Linux daemon
        :

        archive=/local/mnt/filer/alljoyn_build/master
        branch=${GERRIT_BRANCH}
        from_build_bin_zip=$( ls -1trd "$archive/testbot/$branch/trusty_off/bin-dbg.zip" | tail -1 ) || : ok for now

        case "$from_build_bin_zip" in
        ( /*/trusty_off/bin-dbg.zip )
            ls -ld "$from_build_bin_zip" || ci_exit 2 $ci_job, error trap, from_build_bin_zip="$from_build_bin_zip" ;;
        ( "" )  ci_exit 2 $ci_job, no files found like "$archive/../*/testbot/$branch/trusty_off/bin-dbg.zip" ;;
        ( * )   ci_exit 2 $ci_job, trap, something wrong with from_build_bin_zip="$from_build_bin_zip" ;;
        esac

        : from_build_bin_zip="$from_build_bin_zip" ok

        : unzip from_build_bin_zip and move content to alljoyn_bin

        alljoyn_bin="${CI_SCRATCH}/platform/alljoyn_bin"

        mkdir -p "${CI_SCRATCH}/platform" || : ok

        pushd "${CI_SCRATCH}/platform"
            rm -rf alljoyn_bin tmp
            mkdir tmp
            pushd tmp
                ci_unzip "$from_build_bin_zip"
                ls -la
                t=$( ls -1d * | wc -l | sed -e 's/[^0-9]//g' )
                case "$t" in
                ( 1 )
                    mv * ../alljoyn_bin
                    ;;
                ( * )
                    ci_exit 2 $ci_job, something wrong with "$from_build_bin_zip"
                    ;;
                esac
            popd
            rm -rf tmp
            ls -la alljoyn_bin
        popd

        : if another alljoyn-daemon is running right now, wait here a bit

        p=$( pgrep -d, -x alljoyn-daemon ) || : ok
        t=0
        until test "$p" = ""
        do
            : t=$t and still waiting
            ps -fp $p
            test "$t" -gt 600 && ci_exit 2 $ci_job, waited too long for another alljoyn-daemon
            sleep 15
            t=$( expr $t + 15 )
            p=$( pgrep -d, -x alljoyn-daemon ) || : ok
        done

        # FIXME 2015-02-05: end

        ulimit -c unlimited
        ;;
    ( * )
        : not Windows, not Linux, maybe OS X - no alljoyn-daemon
        start_daemon=-S
        ;;
    esac
    ;;
( * )
    : Windows - no alljoyn-daemon
    start_daemon=-S
    ;;
esac

:
: START ajtcltest
:
case "${CI_VERBOSE}" in ( [NnFf]* ) _x=+x ;; ( * ) _x=-x ;; esac

pushd alljoyn/core/ajtcl/unit_test/test_report
    rm -f runall.sh.t
    sed -e 's,\r$,,' < runall.sh > runall.sh.t

    : runall.sh ajtcltest
    bash $_x runall.sh.t $start_daemon -c '*-buildbot.conf' -d "$alljoyn_bin" -- ajtcltest || {
        ci_job_xit=$?
        : FAILURE ajtcltest exit=$ci_job_xit
    }

    :
    : INFO ajtcltest log
    :
    cp ajtcltest-buildbot.conf* alljoyn-daemon.log "${CI_ARTIFACTS}" || : ok
    cp ajtcltest.xml "${CI_ARTIFACTS}" || ci_job_xit=$?
    cp ajtcltest.log "${CI_ARTIFACTS}" || ci_job_xit=$?
    cat ajtcltest.log || ci_job_xit=$?
    :
    :
popd

set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
