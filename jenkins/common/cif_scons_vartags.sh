
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

case "$cif_scons_vartags_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_scons_vartags_xet=cif_xet

echo >&2 + : BEGIN cif_scons_vartags.sh

# function returns strings that evaluate to define some local variables we use often for AJ Std Core processes
#   cwd     : top of AJ Std Core SCons build tree (ie core/alljoyn)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Std Core SCons options OS,CPU,VARIANT
#   stdout  : vartag='string' cputag='string' dist='string' test='string' obj='string'

ci_scons_vartags() {

    : ci_scons_vartags "$@"

    local xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"

    local vartag cputag

    case "$_os" in ( linux | android | darwin | win7 ) ;; ( * ) ci_exit 2 ci_scons_vartags, OS="$_os" ;; esac
    case "$_variant" in
    ( debug )   vartag=dbg ;;
    ( release ) vartag=rel ;;
    ( * )       ci_exit 2 ci_scons_vartags, VARIANT="$_variant" ;;
    esac

    case "$_cpu" in
    ( *64 )     cputag=x64 ;;
    ( *86 )     cputag=x86 ;;
    ( arm* )    cputag=$_cpu ;;
    ( * )       ci_exit 2 ci_scons_vartags, CPU="$_cpu" ;;
    esac

    local dist=${PWD}/build/$_os/$_cpu/$_variant/dist
    local test=${PWD}/build/$_os/$_cpu/$_variant/test
    local obj=${PWD}/build/$_os/$_cpu/$_variant/obj

    echo vartag=$vartag
    echo cputag=$cputag
    echo "dist='$dist'"
    echo "test='$test'"
    echo "obj='$obj'"

    case "$xet" in ( *x* ) set -x ;; esac
}
export -f ci_scons_vartags

# function returns a string that evaluates to some local variables we use often for AJ Thin Core processes
#   cwd     : top of ajtcl SCons build tree (ie core/ajtcl)
#   argv1   : VARIANT : debug,release
#   stdout  : _os='string' _cpu_'string' vartag='string' cputag='string' thin_dist='string'

ci_thin_scons_vartags() {

    : ci_thin_scons_vartags "$@"

    local xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    local _variant="$1"

    local _os _cpu vartag cputag
    case "$( uname )" in
    ( Linux )
        _os=linux
        _cpu=$( uname -m )
        ;;
    ( Darwin )
        _os=darwin
        _cpu=$( uname -m )
        ;;
    ( CYGWIN* | MINGW* )
        _os=win7
        case "$( uname -m )" in ( i686 | *64 ) _cpu=x86_64 ;; ( *86 ) _cpu=x86 ;; esac
        ;;
    ( * )
        ci_exit 2 ci_thin_scons_vartags, trap uname="$( uname -a )"
        ;;
    esac

    case "$_variant" in
    ( debug )   vartag=dbg ;;
    ( release ) vartag=rel ;;
    ( * )       ci_exit 2 ci_thin_scons_vartags, VARIANT="$_variant" ;;
    esac

    case "$_cpu" in
    ( *64 )     cputag=x64 ;;
    ( *86 )     cputag=x86 ;;
    ( arm* )    cputag=$_cpu ;;
    ( * )       ci_exit 2 ci_thin_scons_vartags, CPU="$_cpu" ;;
    esac

    case "${GERRIT_BRANCH}" in
    ( *reorg )
        local thin_dist=${PWD}/dist
        ;;
    ( RB14.12 | RB15.04 | master )
        local thin_dist=${PWD}
        ;;
    ( * )
        local thin_dist=
        ;;
    esac

    echo _os=$_os
    echo _cpu=$_cpu
    echo vartag=$vartag
    echo cputag=$cputag
    echo "thin_dist='$thin_dist'"

    case "$xet" in ( *x* ) set -x ;; esac
}
export -f ci_thin_scons_vartags

    # end processing this file

echo >&2 + : END cif_scons_vartags.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac
