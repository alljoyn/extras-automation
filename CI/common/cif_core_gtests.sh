
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# function runs Google tests for AllJoyn Core (Std and Thin) on any platform except Android device or emulator
#   cwd     : top of AJ Core SCons build tree (ie, just above build/$os/$cpu/$variant/...)
#               -OR-
#             top of ajtcl build tree (ie, in ajtcl)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Std Core SCons options OS,CPU,VARIANT
#   argv4   : BR=[on, off] : "bundled router" -or- "router daemon" (alljoyn-daemon), as in AJ Std Core SCons option BR
#   argv5   : BINDINGS : cpp,c,etc, as in AJ Std Core SCons option BINDINGS
#               -OR-
#             "ajtcl" : for ajtcltest (AJ Thin Core)
#   return  : 0 -or- non-zero : pass -or- fail

    # FIXME : this script should support ajtcltest with BR=off by running a stand-alone alljoyn router daemon (Linux)
    #         or sample router program (Windows) coming from a previous build - location identified by new command-line
    #         parameter(s), "dist"
    #
    #         as of now, this script only supports ajtcltest with BR=on - ie, no stand-alone router

case "$cif_core_gtests_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_core_gtests_xet=cif_xet

echo >&2 + : BEGIN cif_core_gtests.sh

source "${CI_COMMON}/cif_scons_vartags.sh"

ci_core_gtests() {

    case "${CIAJ_GTEST}" in
    ( [NnFf]* )
        :
        : WARNING ci_core_gtests, skipping gtests because CIAJ_GTEST="${CIAJ_GTEST}"
        :
        return 0
        ;;
    esac

    local xet="$-"
    local xit=0

    :
    : ci_core_gtests "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"
    local _br="$4"
    local _bindings="$5"

    local vartag cputag dist test obj daemon_bin daemon_options daemon_exe gtest_list
    case "$_bindings" in
    ( ajtcl )
        # FIXME - not implemented : standalone alljoyn router daemon - separate "dist" location - different daemon_bin, LD_LIBRARY_PATH
        # FIXME - on Windows, use sample router program instead of alljoyn-daemon
        eval $( ci_thin_scons_vartags "$_variant" )
        daemon_bin=FIXME
        daemon_options=
        daemon_exe=
        gtest_list=ajtcltest
        ;;
    ( * )
        eval $( ci_scons_vartags "$@" )
        daemon_bin=$dist/cpp/bin
        daemon_options=
        daemon_exe=
        gtest_list="ajtest cmtest ajctest abouttest"
        ;;
    esac

    local gtest gtest_bin is_required ready_daemon start_daemon ready_address _bus_address daemon_pid

        # fake HOME and TMPDIR should have been done by now, in ci_setenv preamble. better safe than sorry.

    if test "$HOME" = "${WORKSPACE}/home" -a "${WORKSPACE}" != ""
    then
        : HOME="${WORKSPACE}/home" -- good
    else
        :
        : WARNING ci_core_gtests, HOME="$HOME" should be under WORKSPACE="$WORKSPACE"
        :
        export HOME=${WORKSPACE}/home
    fi
    if test "$TMPDIR" = "${WORKSPACE}/tmp"   -a "${WORKSPACE}" != ""
    then
        : TMPDIR="${WORKSPACE}/tmp" -- good
    else
        :
        : WARNING ci_core_gtests, TMPDIR="$TMPDIR" should be under WORKSPACE="$WORKSPACE"
        :
        export TMPDIR=${WORKSPACE}/tmp
    fi
    mkdir "${WORKSPACE}/home" "${WORKSPACE}/tmp" || : ok

        : generate top part of gtest.conf file

    rm -f "${CI_WORK}/gtest.conf"
    cat <<\EoF > "${CI_WORK}/gtest.conf"
[Environment]
    # variable=value

    ER_DEBUG_ALL=0

    # GTest supports the following options, shown with their default value
    # GTEST_OUTPUT=     # None
    # GTEST_ALSO_RUN_DISABLED_TESTS=0   # No
    # GTEST_REPEAT=0    # No
    # GTEST_SHUFFLE=0   # No
    # GTEST_RANDOM_SEED=0       # default pseudo-random seed
    # GTEST_BREAK_ON_FAILURE=0  # no break on failures
    # GTEST_CATCH_EXCEPTIONS=1  # gtest catches exceptions itself

EoF

    mkdir -p "${CI_ARTIFACTS}/$vartag" 2> /dev/null || : ok
    rm -f    "${CI_ARTIFACTS}/$vartag/gtest.alljoyn-daemon.conf"

        : platform=$_os specific

    case "$_os" in
    ( linux )
        export LD_LIBRARY_PATH=$dist/cpp/lib:$dist/c/lib
            # FIXME : ajtcltest should support BR=off
        case "$_br" in
        ( [Oo][Ff][Ff] )
            ready_daemon=T
            ready_address=unix:abstract=alljoyn ### FIXME $( uuidgen )
            daemon_options="--config-file=gtest.alljoyn-daemon.conf --no-udp --no-slap --nofork --print-address --verbosity=5"
            daemon_exe=alljoyn-daemon

            cat <<EoF > "${CI_ARTIFACTS}/$vartag/gtest.alljoyn-daemon.conf"
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
    ( darwin )
        case "$_br" in ( [Oo][Ff][Ff] ) ci_exit 2 ci_core_gtests, BR=off not supported for "$_os" ;; esac
        export LD_LIBRARY_PATH=$dist/cpp/lib
        ready_daemon=F
        ready_address=null:
        ;;
    ( win7 | win10 )
            # FIXME : ajtcltest should support BR=off
        case "$_br" in ( [Oo][Ff][Ff] ) ci_exit 2 ci_core_gtests, BR=off not supported for "$_os" ;; esac
        ready_daemon=F
        ready_address=null:
        ;;
    ( * )
        : START gtest $vartag
        ci_exit 2 ci_core_gtests, no Google Tests for $_os
        ;;
    esac

    ci_savenv


        : run all applicable gtests

    for gtest in $gtest_list
    do
        mkdir -p "${CI_ARTIFACTS}/$vartag" 2> /dev/null || : ok
        rm -f    "${CI_ARTIFACTS}/$vartag/$gtest"*

        start_daemon=$ready_daemon

            : gtest=$gtest specific

        case $gtest in
        ( ajtcltest )
            case "$thin_dist" in
            ( /*/dist )
                gtest_bin=$thin_dist/test
                export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$thin_dist/lib
                ;;
            ( /* )
                gtest_bin=$thin_dist/unit_test
                ;;
            ( * )
                gtest_bin=${PWD}/unit_test
                ;;
            esac
            case "$_os" in ( darwin ) is_required=excused ;; ( * ) is_required=required ;; esac
            start_daemon=F  # FIXME : hardwired for ajtcltest
            ;;
        ( ajtest )
            gtest_bin=$test/cpp/bin
            is_required=required
            ;;
        ( cmtest )
            gtest_bin=$test/cpp/bin
            is_required=required
            start_daemon=F
            ;;
        ( ajctest )
            case "$_bindings" in ( [Cc],* | *,[Cc] | *,[Cc],* | [Cc] ) is_required=required ;; ( * ) is_required=excused ;; esac
            case "$_os" in ( darwin ) is_required=excused ;; esac
            gtest_bin=$test/c/bin
            ;;
        ( abouttest )
            gtest_bin=$test/cpp/bin
            is_required=optional
            ;;
        esac

        if test -f "$gtest_bin/$gtest" -o -f "$gtest_bin/$gtest.exe"
        then
            : OK $gtest exe
        else
            case "$is_required" in
            ( required )
                : START $gtest $vartag
                ci_exit 2 ci_core_gtests, $gtest executable not found
                ;;
            ( optional )
                : START $gtest $vartag
                :
                : WARNING skipping $gtest, executable not found, hope thats OK
                :
                continue
                ;;
            ( excused )
                :
                : INFO skipping $gtest $vartag
                :
                continue
                ;;
            esac
        fi

            : clean fake home and tmp directories before each gtest

        rm -rf "${WORKSPACE}/home" "${WORKSPACE}/tmp" || : ok
            # because rm -rf $HOME/* just feels too dangerous
        mkdir  "${WORKSPACE}/home" "${WORKSPACE}/tmp"

        pushd "$gtest_bin"

            : run $gtest from $PWD

            rm -f $gtest.conf $gtest.log

            case "$start_daemon" in
            ( F | "" )
                    : no alljoyn-daemon

                _bus_address=null:
                ;;
            ( T )
                    : use alljoyn-daemon

                _bus_address=$ready_address

                pushd "$daemon_bin"
                    rm -f $gtest.alljoyn-daemon.log gtest.alljoyn-daemon.conf

                    killall -9 -v alljoyn-daemon || { sleep 2 ; killall -9 -v alljoyn-daemon ; } || : ok

                    ls -l ./$daemon_exe && ./$daemon_exe --version || {
                        : START alljoyn-daemon $vartag
                        ci_exit 2 ci_core_gtests, alljoyn-daemon executable not found
                    }

                    cp "${CI_ARTIFACTS}/$vartag/gtest.alljoyn-daemon.conf" .

                    :
                    : run alljoyn-daemon in background from $PWD
                    :

                    date > $gtest.alljoyn-daemon.log 2>&1
                    ./$daemon_exe $daemon_options >> $gtest.alljoyn-daemon.log 2>&1 < /dev/null &

                    : save alljoyn-daemon pid

                    daemon_pid=$!
                popd
                ;;
            esac

                : complete the generated gtest.conf file

            cat <<EoF > "${CI_ARTIFACTS}/$vartag/$gtest.conf" "${CI_WORK}/gtest.conf" -
[Environment]
    GTEST_OUTPUT=xml:$gtest.xml

    BUS_ADDRESS =$_bus_address
    BUS_ADDRESS1=$_bus_address
    BUS_ADDRESS2=$_bus_address
    BUS_ADDRESS3=$_bus_address

[TestCases]
    # Can select individual tests as well as groups.
    # That is, TestCase selection can look like Foo.Bar=YES, not just Foo=YES.
    # You can also used negative selection, like *=YES followed by Foo.Bar=NO.

    *=Yes
$(
    case "$gtest:$_os:${GERRIT_BRANCH}" in
    ( cmtest:darwin:RB15.04 )
        :
        : WARNING : disabled cmtest case EventTest.Below64Handles1
        :
        echo '
    #
    # CMTEST test case disabled, branch RB15.04, osx build only
    #

    EventTest.Below64Handles1=NO
'
        ;;
    ( ajtcltest:*:* )
        echo '
    #
    # AJTCLTEST test case disabled every time
    #

    SecurityTest=NO
'
        case "$start_daemon" in
        ( F )
            echo '
    #
    # AJTCLTEST test case disabled because no router daemon is available
    #

    BusAttachmentTest.*=NO
'           ;;
        esac
        ;;
    ( ajtest:win10:* )
        case "${CI_JOBTYPE}" in
        ( vfy-* )
            :
            : WARNING : disabled ajtest case "SecurityClaimApplicationTest.*"
            :
            echo '
    #
    # AJTEST test case disabled, windows 10, single-CPU
    #

    SecurityClaimApplicationTest.*=NO
'
            ;;
        esac
        ;;
    esac
)
EoF
            cp "${CI_ARTIFACTS}/$vartag/$gtest.conf" $gtest.conf

                # run the $gtest

            ci_test_harness $gtest $gtest.conf $gtest.log || xit=$?

            cp $gtest.log $gtest.xml "${CI_ARTIFACTS}/$vartag" || : ok
        popd

        case "$start_daemon" in
        ( T )
                : end alljoyn-daemon

            pushd "$daemon_bin"

                :
                : kill alljoyn-daemon
                :
                kill $daemon_pid || { sleep 2 ; kill -9 $daemon_pid ; } || : ok
                sleep 2

                date >> $gtest.alljoyn-daemon.log 2>&1
                cp $gtest.alljoyn-daemon.log "${CI_ARTIFACTS}/$vartag/$gtest.alljoyn-daemon.log" || : ok
            popd
            ;;
        esac

        case $xit in ( 0 ) ;; ( * ) case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) break ;; esac ;; esac
    done

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_core_gtests

    # end processing this file

echo >&2 + : END cif_core_gtests.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac