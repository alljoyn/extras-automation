
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

# function runs Google tests for AllJoyn Core on any platform
#   cwd     : top of AJ Core SCons build tree (ie core/alljoyn)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Core SCons options OS,CPU,VARIANT
#   argv4   : BR=[on, off] : "bundled router" -or- "router daemon" (alljoyn-daemon), as in AJ Core SCons option BR
#   argv5   : BINDINGS : cpp,c,etc, as in AJ Core SCons option BINDINGS
#   return  : 0 -or- non-zero : pass -or- fail

echo >&2 + : BEGIN cif_core_gtests.sh

ci_core_gtests() {

    :
    : ci_core_gtests "$@"
    :

    local _xet="$-"
    local _xit=0

    local os="$1"
    local cpu="$2"
    local variant="$3"
    local br="$4"
    local bindings="$5"

    local vartag cputag dist test

    case "$os" in ( linux | darwin | win7 ) ;; ( * ) ci_exit 2 ci_core_gtests, OS="$os" ;; esac
    case "$variant" in
    ( debug )   vartag=dbg ;;
    ( release ) vartag=rel ;;
    ( * )       ci_exit 2 ci_core_gtests, VARIANT="$variant" ;;
    esac

    case "$cpu" in
    ( *64 )     cputag=x64 ;;
    ( *86 )     cputag=x86 ;;
    ( arm* )    cputag=$cpu ;;
    ( * )       ci_exit 2 ci_core_gtests, CPU="$cpu" ;;
    esac

    dist=$PWD/build/$os/$cpu/$variant/dist
    test=$PWD/build/$os/$cpu/$variant/test

    local gtest gtestbin is_required ready_daemon start_daemon _x

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

    case "$os" in
    ( linux )
        export LD_LIBRARY_PATH=$dist/cpp/lib:$dist/c/lib
        case "$br" in ( [Oo][Ff][Ff] ) ready_daemon=-s ;; ( * ) ready_daemon=-S ;; esac
        ;;
    ( darwin )
        export LD_LIBRARY_PATH=$dist/cpp/lib
        ready_daemon=-S
        ;;
    ( win7 )
        ready_daemon=-S
        ;;
    ( * )
        : START $gtest $vartag
        ci_exit 2 ci_core_gtests, no Google Test yet for $os
        ;;
    esac

    ci_savenv

    for gtest in ajtest cmtest ajctest abouttest
    do
        start_daemon=$ready_daemon
        case $gtest in
        ( ajtest )
            gtestbin=$test/cpp/bin
            is_required=required
            ;;
        ( cmtest )
            gtestbin=$test/cpp/bin
            is_required=required
            start_daemon=-S
            ;;
        ( ajctest )
            case "$bindings" in ( [Cc],* | *,[Cc] | *,[Cc],* | [Cc] ) is_required=required ;; ( * ) is_required=excused ;; esac
            case "$os" in ( darwin ) is_required=excused ;; esac
            gtestbin=$test/c/bin
            ;;
        ( abouttest )
            gtestbin=$test/cpp/bin
            is_required=optional
            ;;
        esac

        if test -f "$gtestbin/$gtest" -o -f "$gtestbin/$gtest.exe"
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

        if test -f "$gtestbin/test_report/$gtest-buildbot.conf"
        then
            : OK $gtest-buildbot.conf
        else
            : START $gtest $vartag
            ci_exit 2 ci_core_gtests, $gtest-buildbot config file not found
        fi

        rm -rf "${WORKSPACE}/home"/* "${WORKSPACE}/tmp"/* || : ok
            # because rm -rf $HOME/* just feels too dangerous

        case "${CI_VERBOSE}" in ( [NnFf]* ) _x=+x ;; ( * ) _x=-x ;; esac

        :
        : START $gtest $vartag
        :
        pushd "$gtestbin/test_report"
            rm -f runall.sh.t
            sed -e 's,\r$,,' < runall.sh > runall.sh.t

            : runall.sh $gtest
            bash $_x runall.sh.t $start_daemon -t "$test" -c '*-buildbot.conf' -- $gtest || {
                _xit=$?
                :
                : FAILURE $gtest exit=$_xit
                :
            }
            :
            : INFO $gtest log
            :
            cat $gtest.log
            cp $gtest-buildbot.conf* "${CI_ARTIFACTS}" || : ok
            cp alljoyn-daemon.log "${CI_ARTIFACTS}/$gtest.alljoyn-daemon.log" || : ok
            cp $gtest.xml "${CI_ARTIFACTS}" || _xit=$?
            cp $gtest.log "${CI_ARTIFACTS}"
        popd
    done

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $_xit
}
export -f ci_core_gtests

echo >&2 + : END cif_core_gtests.sh
