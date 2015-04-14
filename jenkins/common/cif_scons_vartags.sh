
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

# function returns a string that evaluates to some local variables we use often for AJ Core processes
#   cwd     : top of AJ Core SCons build tree (ie core/alljoyn)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Core SCons options OS,CPU,VARIANT

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

    echo vartag=$vartag cputag=$cputag
    echo "dist='$dist'"
    echo "test='$test'"
    echo "obj='$obj'"

    case "$xet" in ( *x* ) set -x ;; esac
}
export -f ci_scons_vartags

    # end processing this file

echo >&2 + : END cif_scons_vartags.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac
