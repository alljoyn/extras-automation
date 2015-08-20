
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

# function runs JUnit tests for AllJoyn Core on any platform except Android (because emulator) or Mac/OSX (because no java)
#   cwd     : top of AJ Core SCons build tree (ie, just above build/$os/$cpu/$variant/...)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Core SCons options OS,CPU,VARIANT
#   argv4   : BR=[on, off] : "bundled router" -or- "router daemon" (alljoyn-daemon), as in AJ Core SCons option BR
#   return  : 0 -or- non-zero : pass -or- fail

case "$cif_core_junits_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_core_junits_xet=cif_xet

echo >&2 + : BEGIN cif_core_junits.sh

source "${CI_COMMON}/cif_scons_vartags.sh"

ci_core_junits() {

    local xet="$-"
    local xit=0

    :
    : ci_core_junits "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"
    local _br="$4"

    local vartag cputag dist test obj
    eval $( ci_scons_vartags "$@" )

    case "$_os" in
    ( android )
        : no-op for $_os
        date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
        case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
        return $xit
        ;;
    esac

    local ready_daemon start_daemon ready_address _bus_address daemon_bin daemon_options daemon_pid daemon_exe

        # fake HOME and TMPDIR should have been done by now, in ci_setenv preamble. better safe than sorry.

    if test "$HOME" = "${WORKSPACE}/home" -a "${WORKSPACE}" != ""
    then
        : HOME="${WORKSPACE}/home" -- good
    else
        :
        : WARNING ci_core_junits, HOME="$HOME" should be under WORKSPACE="$WORKSPACE"
        :
        export HOME=${WORKSPACE}/home
    fi
    if test "$TMPDIR" = "${WORKSPACE}/tmp"   -a "${WORKSPACE}" != ""
    then
        : TMPDIR="${WORKSPACE}/tmp" -- good
    else
        :
        : WARNING ci_core_junits, TMPDIR="$TMPDIR" should be under WORKSPACE="$WORKSPACE"
        :
        export TMPDIR=${WORKSPACE}/tmp
    fi
    mkdir "${WORKSPACE}/home" "${WORKSPACE}/tmp" || : ok

    mkdir -p "${CI_ARTIFACTS}/$vartag" 2> /dev/null || : ok
    rm -f    "${CI_ARTIFACTS}/$vartag/junit"*

    daemon_bin=$dist/cpp/bin
    daemon_options=
    daemon_exe=

        : platform=$_os specific

    case "$_os" in
    ( linux )
        export LD_LIBRARY_PATH=$dist/cpp/lib:$dist/c/lib
        case "$_br" in
        ( [Oo][Ff][Ff] )
            ready_daemon=T
            ready_address=unix:abstract=alljoyn ### FIXME $( uuidgen )
            daemon_options="--config-file=junit.alljoyn-daemon.conf --no-udp --no-slap --nofork --print-address --verbosity=5"
            daemon_exe=alljoyn-daemon

            cat <<EoF > "${CI_ARTIFACTS}/$vartag/junit.alljoyn-daemon.conf"
<?xml version= "1.0"?>
<busconfig>
  <type>alljoyn</type>
  <!--
    Only listen on a local socket. (abstract=/path/to/socket
    means use abstract namespace, don't really create filesystem
    file; only Linux supports this. Use path=/whatever on other
    systems.)
    -->
  <listen>$ready_address</listen>
  <listen>tcp:addr=0.0.0.0,port=9955</listen>
  <limit name="auth_timeout">32768</limit>
  <limit name="max_incomplete_connections">16</limit>
  <limit name="max_completed_connections">32</limit>
  <limit name="max_remote_clients_tcp">0</limit>"
  <flag name="restrict_untrusted_clients">false</flag>
  <!--
    Allow everything, D-Bus socket is protected by unix filesystem permissions
    -->
  <policy context="default">
    <allow send_interface="*"/>
    <allow receive_interface="*"/>
    <allow own="*"/>
    <allow user="*"/>
  </policy>
</busconfig>
EoF
            ;;
        ( * )
            ready_daemon=F
            ready_address=null:
            ;;
        esac
        ;;
    ( win7 | win10 )
        case "$_br" in ( [Oo][Ff][Ff] ) ci_exit 2 ci_core_junits, BR=off not supported for "$_os" ;; esac
        ready_daemon=F
        ready_address=null:
        ;;
    ( * )
        : START junit $vartag
        ci_exit 2 ci_core_junits, no JUnit Test for $_os
        ;;
    esac

    ci_savenv

    start_daemon=$ready_daemon

        : clean fake home and tmp directories before junit

    rm -rf "${WORKSPACE}/home" "${WORKSPACE}/tmp" || : ok
        # because rm -rf $HOME/* just feels too dangerous
    mkdir  "${WORKSPACE}/home" "${WORKSPACE}/tmp"

    pushd "$test/junit"

        : run junit from $PWD

        rm -f junit.log

        case "$start_daemon" in
        ( F | "" )
                : no alljoyn-daemon

            _bus_address=null:
            ;;
        ( T )
                : use alljoyn-daemon

            _bus_address=$ready_address

            pushd "$daemon_bin"
                rm -f junit.alljoyn-daemon.log junit.alljoyn-daemon.conf

                killall -9 -v alljoyn-daemon || { sleep 2 ; killall -9 -v alljoyn-daemon ; } || : ok

                ls -l ./$daemon_exe && ./$daemon_exe --version || {
                        : START alljoyn-daemon $vartag
                    ci_exit 2 ci_core_junits, alljoyn-daemon executable not found
                }

                cp "${CI_ARTIFACTS}/$vartag/junit.alljoyn-daemon.conf" .

                :
                : run alljoyn-daemon in background from $PWD
                :

                date > junit.alljoyn-daemon.log 2>&1
                ./$daemon_exe $daemon_options >> junit.alljoyn-daemon.log 2>&1 < /dev/null &

                : save alljoyn-daemon pid

                daemon_pid=$!
            popd
            ;;
        esac

        :
        : START junit $vartag
        :
        # override some default properties on ant command line because this runs from alljoyn/build/$os/$cpu/$variant/test/junit, not from alljoyn
        time ant < /dev/null -f build.xml -Ddist=../../dist/java -Dclasses=test/classes -Dtest=. -DOS=$_os -DCPU=$_cpu -DVARIANT=$_variant -Dorg.alljoyn.bus.address=$_bus_address test | tee junit.log
        tail -10 junit.log | grep -q 'BUILD SUCCESSFUL' || {
            xit=1
            :
            : FAILURE junit
            :
        }

        cp junit.log "${CI_ARTIFACTS}/$vartag" || : ok
        if test -d ./reports/junit
        then
            ci_zip_simple_artifact "$PWD/reports/junit" "junit-$vartag" || : ok
        fi

        case "$start_daemon" in
        ( T )
                : end alljoyn-daemon

            pushd "$daemon_bin"

                :
                : kill alljoyn-daemon
                :
                kill $daemon_pid || { sleep 2 ; kill -9 $daemon_pid ; } || : ok
                sleep 2

                date >> junit.alljoyn-daemon.log 2>&1
                cp junit.alljoyn-daemon.log "${CI_ARTIFACTS}/$vartag/junit.alljoyn-daemon.log" || : ok
            popd
            ;;
        esac
    popd

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}

export -f ci_core_junits

# function prepares "test" tree to run JUnit tests for AllJoyn Core on any platform except Android (because emulator) or Mac/OSX (because no java)
#   cwd     : top of AJ Core SCons build tree (ie, just above build/$os/$cpu/$variant/... AND alljoyn_core, alljoyn_java, etc)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Core SCons options OS,CPU,VARIANT
#   return  : 0 -or- non-zero : pass -or- fail

ci_core_ready_junits() {

    local xet="$-"
    local xit=0

    :
    : ci_ready_core_junits "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"

    local vartag cputag dist test obj
    eval $( ci_scons_vartags "$@" )

    case "$_os" in
    ( android )
        : no-op for $_os
        date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
        case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
        return $xit
        ;;
    esac

    rm -rf   "$test/junit"
    mkdir -p "$test/junit" || : ok
    cp -p build.xml "$test/junit"
    pushd "$obj/alljoyn_java"
        cp -rp test "$test/junit"
    popd

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}

export -f ci_core_ready_junits

    # end processing this file

echo >&2 + : END cif_core_junits.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac
