
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

# function runs JUnit tests for AllJoyn Core on any platform (except Mac/OSX, because no java binding)
#   cwd     : top of AJ Core SCons build tree (ie core/alljoyn)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Core SCons options OS,CPU,VARIANT
#   argv4   : BR=[on, off] : "bundled router" -or- "router daemon" (alljoyn-daemon), as in AJ Core SCons option BR
#   return  : 0 -or- non-zero : pass -or- fail

echo >&2 + : BEGIN cif_core_junits.sh

ci_core_junits() {

    :
    : ci_core_junits "$@"
    :

    local _xet="$-"
    local _xit=0

    local os="$1"
    local cpu="$2"
    local variant="$3"
    local br="$4"

    local vartag cputag dist test

    case "$os" in ( linux | win7 ) ;; ( * ) ci_exit 2 ci_core_junits, OS="$os" ;; esac
    case "$variant" in
    ( debug )   vartag=dbg ;;
    ( release ) vartag=rel ;;
    ( * )       ci_exit 2 ci_core_junits, VARIANT="$variant" ;;
    esac

    case "$cpu" in
    ( *64 )     cputag=x64 ;;
    ( *86 )     cputag=x86 ;;
    ( arm* )    cputag=$cpu ;;
    ( * )       ci_exit 2 ci_core_junits, CPU="$cpu" ;;
    esac

    dist=$PWD/build/$os/$cpu/$variant/dist
    test=$PWD/build/$os/$cpu/$variant/test

    local start_daemon _x

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

    case "$os" in
    ( linux )
        case "$br" in ( [Oo][Ff][Ff] ) start_daemon=-s ;; ( * ) start_daemon=-S ;; esac
        export LD_LIBRARY_PATH=$dist/cpp/lib:$dist/c/lib
        ;;
    ( win7 )
        start_daemon=-S
        ;;
    ( * )
        : START JUnit $vartag
        ci_exit 2 ci_core_junits, no JUnit tests yet for $os
        ;;
    esac

    rm -rf "${WORKSPACE}/home"/* "${WORKSPACE}/tmp"/* || : ok
        # because rm -rf $HOME/* just feels too dangerous

    case "${CI_VERBOSE}" in ( [NnFf]* ) _x=+x ;; ( * ) _x=-x ;; esac

    # FIXME 20150219, awallace: CLASSPATH
    unset CLASSPATH

    ci_savenv

    :
    : START JUnit $vartag
    :
    pushd alljoyn_java/test_report
        rm -f runall.sh.t
        if test -f runall.top.sh -a -f ../build.xml.top
        then
            # 20120705: new stuff added by georgen, awallace
            : using runall.top.sh
            sed -e 's,\r$,,' < runall.top.sh > runall.sh.t
        else
            # 20150116: the above fork, added 20120705, uses materials which are now obsolete.
            #           this fork means that stuff has been cleaned up in this source version
            sed -e 's,\r$,,' < runall.sh > runall.sh.t
        fi

        : runall.sh JUnit
        bash $_x runall.sh.t $start_daemon -o $os -c $cpu -v $variant || {
            _xit=$?
            :
            : FAILURE JUnit exit=$_xit
            :
        }

        :
        : INFO JUnit log
        :
        cat junit.log
        cp alljoyn-daemon.log "${CI_ARTIFACTS}/junit.alljoyn-daemon.log" || : ok
        cp data/TESTS-TestSuites.xml "${CI_ARTIFACTS}/junit.TESTS-TestSuites.xml" || _xit=$?
        cp junit.log "${CI_ARTIFACTS}"
    popd

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $_xit
}
export -f ci_core_junits

echo >&2 + : END cif_core_junits.sh
