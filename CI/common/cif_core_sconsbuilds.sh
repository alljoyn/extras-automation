
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

case "$cif_core_sconsbuilds_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_core_sconsbuilds_xet=cif_xet

source "${CI_COMMON}/cif_scons_vartags.sh"

echo >&2 + : BEGIN cif_core_sconsbuilds.sh

# function runs scons builds for AllJoyn Std Core for all targets except iOS
# producing bins to run google tests and junit on the target
#   cwd     : top of AJ Std Core SCons build tree (ie core/alljoyn)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Std Core SCons options OS,CPU,VARIANT
#   argv4   : BR=[on, off] : "bundled router" -or- "router daemon" (alljoyn-daemon), as in AJ Std Core SCons option BR
#   argv5   : BINDINGS : cpp,c,etc, as in AJ Std Core SCons option BINDINGS

ci_core_sconsbuild() {

    local xet="$-"
    local xit=0

    :
    : ci_core_sconsbuild "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"

    local vartag cputag dist test obj
    eval $( ci_scons_vartags "$@" )

    case "${CI_VERBOSE}" in ( [NnFf]* ) local _verbose=0 ;; ( * ) local _verbose=1 ;; esac

    case "${CIAJ_BINDINGS}" in
    ( js,* | *,js,* | *,js )
        local _gecko_base=$( ci_natpath "${GECKO_BASE}" )
        local _jsdoc_dir=$( ci_natpath "${JSDOC_DIR}" )
        ;;
    ( * )
        local _gecko_base=
        local _jsdoc_dir=
        ;;
    esac

    case "${CIAJ_GTEST}" in
    ( [NnFf]* ) local _gtest_dir= ;;
    ( * )       local _gtest_dir=$( ci_natpath "${GTEST_DIR}" ) ;;
    esac

    case "${CIAJ_OS}" in
    ( linux )
        local _uncrustify=$( uncrustify --version ) || : ok
        case "$_uncrustify" in
        ( uncrustify* )
            case "${GERRIT_BRANCH}/$_uncrustify" in
            ( RB14.12/uncrustify\ 0.61* )
                local _ws=off
                :
                : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
                :
                ;;
            ( RB14.12/uncrustify\ 0.57* )
                local _ws=detail
                ;;
            ( */uncrustify\ 0.61* )
                local _ws=detail
                ;;
            ( * )
                local _ws=off
                :
                : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
                :
                ;;
            esac
            ;;
        ( * )
            local _ws=off
            :
            : WARNING $ci_job, uncrustify not found: skipping Whitespace scan
            :
            ;;
        esac
        ;;
    ( * )
        local _ws=off
        ;;
    esac

    unset AJ_OS AJ_CPU AJ_VARIANT AJ_BINDINGS AJ_BR AJ_POLICYDB AJ_CRYPTO AJ_MSVC_VERSION AJ_ANDROID_API_LEVEL
    unset AJ_GECKO_BASE AJ_JSDOC_DIR AJ_GTEST_DIR AJ_ANDROID_SDK AJ_ANDROID_NDK AJ_ANDROID_SRC

    :
    : START scons $vartag $cputag
    :

    ci_scons -j "$NUMBER_OF_PROCESSORS" OS=$_os CPU=$_cpu VARIANT=$_variant \
        ${CIAJ_BINDINGS:+BINDINGS=}"${CIAJ_BINDINGS}" \
        ${CIAJ_BR:+BR=}"${CIAJ_BR}" \
        ${CIAJ_POLICYDB:+POLICYDB=}"${CIAJ_POLICYDB}" \
        ${CIAJ_CRYPTO:+CRYPTO=}"${CIAJ_CRYPTO}" \
        ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}"${CIAJ_MSVC_VERSION}" \
        ${CIAJ_ANDROID_API_LEVEL:+ANDROID_API_LEVEL=}"${CIAJ_ANDROID_API_LEVEL}" \
        ${_gecko_base:+GECKO_BASE=}"$_gecko_base" \
        ${_jsdoc_dir:+JSDOC_DIR=}"$_jsdoc_dir" \
        ${_gtest_dir:+GTEST_DIR=}"$_gtest_dir" \
        ${ANDROID_SDK:+ANDROID_SDK=}"$ANDROID_SDK" \
        ${ANDROID_NDK:+ANDROID_NDK=}"$ANDROID_NDK" \
        ${ANDROID_SRC:+ANDROID_SRC=}"$ANDROID_SRC" \
        V=$_verbose WS=$_ws DOCS=html || xit=$?

    ci_showfs "$dist" "$test"

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_core_sconsbuild

# function runs scons builds for AllJoyn Std Core / test_tools for all targets except iOS
#   cwd     : top of test_tools build tree (ie core/test/scl)
#   argv1,2,3 : OS,CPU,VARIANT : as in build/$OS/$CPU/$VARIANT/dist path, as in AJ Std Core SCons options OS,CPU,VARIANT

ci_core_test_sconsbuild() {

    local xet="$-"
    local xit=0

    :
    : ci_core_test_sconsbuild "$@"
    :
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    local _os="$1"
    local _cpu="$2"
    local _variant="$3"

    local vartag cputag dist test obj
    eval $( ci_scons_vartags "$@" )

    case "${CI_VERBOSE}" in ( [NnFf]* ) local _verbose=0 ;; ( * ) local _verbose=1 ;; esac

    case "${CIAJ_GTEST}" in
    ( [NnFf]* ) local _gtest_dir= ;;
    ( * )       local _gtest_dir=$( ci_natpath "${GTEST_DIR}" ) ;;
    esac

    unset AJ_OS AJ_CPU AJ_VARIANT AJ_BINDINGS AJ_BR AJ_POLICYDB AJ_CRYPTO AJ_MSVC_VERSION AJ_ANDROID_API_LEVEL
    unset AJ_GECKO_BASE AJ_JSDOC_DIR AJ_GTEST_DIR AJ_ANDROID_SDK AJ_ANDROID_NDK AJ_ANDROID_SRC

    :
    : START scons $vartag $cputag
    :

    ci_scons OS=$_os CPU=$_cpu VARIANT=$_variant \
        ${CIAJ_BR:+BR=}"${CIAJ_BR}" \
        ${CIAJ_POLICYDB:+POLICYDB=}"${CIAJ_POLICYDB}" \
        ${CIAJ_CRYPTO:+CRYPTO=}"${CIAJ_CRYPTO}" \
        ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}"${CIAJ_MSVC_VERSION}" \
        ${CIAJ_ANDROID_API_LEVEL:+ANDROID_API_LEVEL=}"${CIAJ_ANDROID_API_LEVEL}" \
        ${_gtest_dir:+GTEST_DIR=}"$_gtest_dir" \
        ${ANDROID_SDK:+ANDROID_SDK=}"$ANDROID_SDK" \
        ${ANDROID_NDK:+ANDROID_NDK=}"$ANDROID_NDK" \
        ${ANDROID_SRC:+ANDROID_SRC=}"$ANDROID_SRC" \
        V=$_verbose WS=off DOCS=none || xit=$?

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
    return $xit
}
export -f ci_core_test_sconsbuild

    # end processing this file

echo >&2 + : END cif_core_sconsbuilds.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac
