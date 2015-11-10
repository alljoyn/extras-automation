
#    Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright (c) Open Connectivity Foundation and Contributors to AllSeen
#    Alliance. All rights reserved.
#
#    Permission to use, copy, modify, and/or distribute this software for
#    any purpose with or without fee is hereby granted, provided that the
#    above copyright notice and this permission notice appear in all
#    copies.
#
#     THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#     WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#     WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
#     AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
#     DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#     PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#     TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#     PERFORMANCE OF THIS SOFTWARE.

# general CI Jenkins build environment and workspace folder setup

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file, which will define it

echo >&2 + : BEGIN ci_setenv.sh

ci_xet="$-"    # export: not yet
case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    # use bash built-ins only, until PATH is checked

ci_exit() {
    # general purpose error exit
    set +ex
    local xit
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    case "$1" in ( [0-9] | [1-9][0-9] | [1-9][0-9][0-9] ) xit=$1 ; shift ;; ( * ) xit=2 ;; esac
    case $xit in ( 0 ) echo >&2 + : EXIT "$@" ;; ( * ) echo >&2 + : ERROR "$@" ;; esac

    case "$ci_xet" in
    ( *i* )
        # interactive shell
        echo > /dev/tty "
=======
ci_exit $@
=======

Waiting for you to interrupt.  If you continue, this shell will exit.
"
        set -x
        read < /dev/tty junk
        ;;
    esac
    exit $xit
    exit 2
}
# export -f ci_exit # not yet

    # reset PATH to CI_SHELLPATH, if given
export CI_PATH_PREV=$PATH
case "${CI_SHELLPATH}" in
( "" )      ;;
( *\;* )    ci_exit 2 ci_setenv.sh, CI_SHELLPATH="${CI_SHELLPATH}" has semicolon ;;
( /*:/* )   export PATH="${CI_SHELLPATH}" ;;
( * )       ci_exit 2 ci_setenv.sh, CI_SHELLPATH="${CI_SHELLPATH}" looks wrong ;;
esac

unset BASH_ENV
unset CDPATH
unset ENV

    # make sure PATH is sane
\ls > /dev/null || {
    echo >&2 + : INFO : If WINDOWS, CI_SHELLPATH="${CI_SHELLPATH}" should include /bin as seen by CI_SHELL_W="${CI_SHELL_W}"
    ci_exit 2 ci_setenv.sh, PATH="$PATH" failed sanity ck
}
    # normal *nix commands can be used now


    # WORKSPACE must exist and it must be equivalent to the cwd

case "${WORKSPACE}" in
( "" )
    ci_exit 2 ci_setenv.sh, env var WORKSPACE is missing
    ;;
( /* )
    case "${CI_SHELL_W}" in ( "" ) ;; ( * ) ci_setenv.sh, WORKSPACE="${WORKSPACE}" is not Windows but env var CI_SHELL_W="${CI_SHELL_W}" exists ;; esac
    ;;
( [A-Za-z]:\\* )
    case "${CI_SHELL_W}" in ( "" ) ci_setenv.sh, WORKSPACE="${WORKSPACE}" looks like Windows but env var CI_SHELL_W is missing ;; esac
    ;;
( * )
    ci_exit 2 ci_setenv.sh, WORKSPACE="${WORKSPACE}" does not look like a full path
    ;;
esac

_i=$( pwd -P | tr 'a-z' 'A-Z' )
_j=$( cd "${WORKSPACE}" && pwd -P | tr 'a-z' 'A-Z' )
case "$_j" in
( "" )
    ci_exit 2 ci_setenv.sh, failed cd to WORKSPACE="${WORKSPACE}"
    ;;
esac
case "$_i" in
( $_j )
    : good
    ;;
( * )
    ci_exit 2 ci_setenv.sh, current pwd="$_i" but WORKSPACE="${WORKSPACE}" pwd="$_j"
    ;;
esac

    # ci_savenv functions

if test -f "${CI_COMMON_PART}/cif_savenv.sh"
then
    source "${CI_COMMON_PART}/cif_savenv.sh"
else
    ci_exit 2 ci_setenv.sh, '${CI_COMMON_PART}'/cif_savenv.sh not found. CI_COMMON_PART="${CI_COMMON_PART}"
fi
    # WORKSPACE path is known now. Will convert WORKSPACE path from Windows to *nix later, if needed

    # save the initial environment as it exists before ci_setenv changes it - relocate the files later

    ci_declare_env > setenv00.sh
    declare -pfx   > setfun00.sh

export ci_xet
export -f ci_exit
export -f ci_declare_env
export -f ci_savenv

    # general ci functions

ls -ld "${CI_COMMON_PART}/cif_setenv.sh" > /dev/null || \
    ci_exit 2 ci_setenv.sh, CI_COMMON_PART/cif_setenv.sh not found. CI_COMMON_PART="${CI_COMMON_PART}"
source "${CI_COMMON_PART}/cif_setenv.sh"

    # ck existing env variables

ci_ck_partpath CI_JOBTYPE CI_NODETYPE CI_SRC_AUTOMATION_PART CI_JOBSCRIPTS_PART CI_NODESCRIPTS_PART CI_COMMON_PART
ci_ck_found WORKSPACE

    # set some common env variables

export CI_SRC_AUTOMATION=${WORKSPACE}/${CI_SRC_AUTOMATION_PART}
export CI_COMMON=${WORKSPACE}/${CI_COMMON_PART}
export CI_JOBSCRIPTS=${WORKSPACE}/${CI_JOBSCRIPTS_PART}
export CI_NODESCRIPTS=${WORKSPACE}/${CI_NODESCRIPTS_PART}
export CI_GENVERSION_PY=${CI_COMMON}/genversion.py
export CI_TEST_HARNESS_PY=${CI_COMMON}/test_harness.py

ci_ck_fullpath CI_JOBSCRIPTS CI_NODESCRIPTS
ci_ck_found CI_SRC_AUTOMATION CI_COMMON CI_GENVERSION_PY CI_TEST_HARNESS_PY

export CI_WORK=${WORKSPACE}/work
export CI_SCRATCH=${WORKSPACE}/scratch
export CI_SCRATCH_ARTIFACTS=${CI_SCRATCH}/artifacts
export CI_ARTIFACTS=${WORKSPACE}/artifacts
export CI_ARTIFACTS_ENV=${CI_ARTIFACTS}/env

ci_ck_fullpath CI_WORK CI_SCRATCH CI_SCRATCH_ARTIFACTS CI_ARTIFACTS CI_ARTIFACTS_ENV

export HOME=${WORKSPACE}/home
export TMP=${WORKSPACE}/tmp
export TMPDIR=${WORKSPACE}/tmp

mkdir -p "$HOME" 2>/dev/null    || : error ignored
mkdir -p "$TMP" 2>/dev/null     || : error ignored
mkdir -p "${CI_WORK}" 2>/dev/null   || : error ignored
mkdir -p "${CI_SCRATCH}" 2>/dev/null  || : error ignored
mkdir -p "${CI_SCRATCH_ARTIFACTS}" 2>/dev/null     || : error ignored
mkdir -p "${CI_ARTIFACTS}" 2>/dev/null  || : error ignored
mkdir -p "${CI_ARTIFACTS_ENV}" 2>/dev/null  || : error ignored

# force_home and force_tmp allow the job to fallback to "real" home or tmp, if needed
# optional, defined in Jenkins Node config

case "${CI_FORCE_HOME}" in ( "" ) export CI_FORCE_HOME=$HOME ;; esac
case "${CI_FORCE_TMP}"  in ( "" ) export CI_FORCE_TMP=$TMP ;; esac

case "${CI_SHELL_W}" in
( "" )  # not Windows

        # define NUMBER_OF_PROCESSORS env variable - Windows already has NUMBER_OF_PROCESSORS built-in
    _n=$( grep < /proc/cpuinfo '^processor.*[0-9]$' | wc -l | sed -e 's/[^0-9]//g' ) || : ok
    case "$_n" in ( "" | 0 | *[!0-9]* ) _n=1 ;; esac
    case "$NUMBER_OF_PROCESSORS" in ( "" | 0 | *[!0-9]* ) export NUMBER_OF_PROCESSORS=$_n ;; esac
    ;;
( * )   # Windows with msysgit or cygwin

        # make sure NUMBER_OF_PROCESSORS env variable is defined
    case "$NUMBER_OF_PROCESSORS" in
    ( "" | *[!0-9]* | 0 )
        echo >&2 + : WARNING ci_setenv.sh, missing or invalid NUMBER_OF_PROCESSORS="$NUMBER_OF_PROCESSORS"
        export NUMBER_OF_PROCESSORS=1
        ;;
    esac

    # additional env variables commonly used on Windows, like USERPROFILE
    _home_w=$( ci_natpath "$HOME" )
    case "$_home_w" in ( [A-Z]:\\* ) ;; ( * ) ci_exit 2 ci_setenv.sh, "HOME='$HOME', ci_natpath(HOME)='$_home_w'" ;; esac
    _tmp_w=$( ci_natpath "$TMP" )
    case "$_tmp_w" in ( [A-Z]:\\* ) ;; ( * ) ci_exit 2 ci_setenv.sh, "TMP='$TMP', ci_natpath(TMP)='$_tmp_w'" ;; esac

    CI_PATH_PREV_W=$(
        j=""
        echo "$CI_PATH_PREV" | tr ':' '\n' | while read -r i
        do
            case "$i" in ( "" ) continue ;; esac
            echo -n "$j$( ci_natpath "$i" )"
            j=\;
        done
    )

    export HOMEDRIVE=${_home_w%%\\*}
    export HOMEPATH=${_home_w#?:}
    export USERPROFILE=$_home_w
    export LOCALAPPDATA=$_home_w
    export TEMP=$_tmp_w

    _force_home_w=$( ci_natpath "${CI_FORCE_HOME}" )
    _force_tmp_w=$( ci_natpath "${CI_FORCE_TMP}" )
    export CI_FORCE_HOMEDRIVE=${_force_home_w%%\\*}
    export CI_FORCE_HOMEPATH=${_force_home_w#?:}
    export CI_FORCE_USERPROFILE=$_force_home_w
    export CI_FORCE_LOCALAPPDATA=$_force_home_w
    export CI_FORCE_TEMP=$_force_tmp_w

    # write setenv.bat file for CMD processes to use later
    cat <<EOF | sed -e 's,$,\r,' > "${CI_ARTIFACTS_ENV}/ci_setenv.bat"
$(
    case "${CI_VERBOSE}" in ( [NnFf]* ) echo "@echo off" ;; ( * ) echo "@echo on" ;; esac
)

    REM ci_setenv.sh

$(
    case "${CI_SHELLPATH_W}" in
    ( "" )
        echo "set PATH=$CI_PATH_PREV_W"
        ;;
    ( * )
        echo "set PATH=${CI_SHELLPATH_W}"
        ;;
    esac
)
set HOME=$_home_w
set HOMEDRIVE=${_home_w%%\\*}
set HOMEPATH=${_home_w#?:}
set USERPROFILE=$_home_w
set LOCALAPPDATA=$_home_w
set TEMP=$_tmp_w
set TMP=$_tmp_w
set TMPDIR=$_tmp_w
set CI_ARTIFACTS=$( ci_natpath "${CI_ARTIFACTS}" )
set CI_ARTIFACTS_ENV=$( ci_natpath "${CI_ARTIFACTS_ENV}" )
set CI_COMMON=$( ci_natpath "${CI_COMMON}" )
set CI_GENVERSION_PY=$( ci_natpath "${CI_GENVERSION_PY}" )
set CI_TEST_HARNESS_PY=$( ci_natpath "${CI_TEST_HARNESS_PY}" )
set CI_SRC_AUTOMATION=$( ci_natpath "${CI_SRC_AUTOMATION}" )
set CI_JOBSCRIPTS=$( ci_natpath "${CI_JOBSCRIPTS}" )
set CI_NODESCRIPTS=$( ci_natpath "${CI_NODESCRIPTS}" )
set CI_WORK=$( ci_natpath "${CI_WORK}" )
set CI_SCRATCH=$( ci_natpath "${CI_SCRATCH}" )
set CI_SCRATCH_ARTIFACTS=$( ci_natpath "${CI_SCRATCH_ARTIFACTS}" )
set WORKSPACE=$( ci_natpath "${WORKSPACE}" )
EOF
    case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) : INFO show ci_setenv.bat ; cat "${CI_ARTIFACTS_ENV}/ci_setenv.bat" ;; esac
    ;;
esac

    # relocate the file containing the original env, saved earlier
if test -f "${CI_ARTIFACTS_ENV}/setenv00.sh"
then
    echo >&2 + : INFO will not overwrite existing setenv.sh files
    diff "${CI_ARTIFACTS_ENV}/setenv00.sh" setenv00.sh || : ok
    rm -f setenv00.sh setfun00.sh
    export CI_ENV=
else
    export CI_ENV=${CI_ARTIFACTS_ENV}
    mkdir -p "${CI_ENV}" || : ok
    mv -f setenv00.sh setfun00.sh "${CI_ENV}"
fi

    # process upstream job 1 environment, if any
_t=$( ls "${CI_SCRATCH}/up1/artifacts/env/setenv.sh" ) || : ok
case "$_t" in
( /*/setenv.sh )
    # found setenv.sh from upstream job
    ci_savenv
    ci_upsetenv 1
    echo >&2 + : source up1setenv.sh
    if ls -ld "${CI_ARTIFACTS_ENV}/up1setenv.properties" 2>/dev/null
    then
        echo >&2 + : INFO will not overwrite existing up1setenv.properties files
        source "${CI_ARTIFACTS_ENV}/up1setenv.sh"
    else
        source "${CI_ARTIFACTS_ENV}/up1setenv.sh" > "${CI_WORK}/up1setenv.properties"
            # add backslashes to contination lines
            # the above "source up1setenv.sh" can not go in a pipeline with awk (below),
            #   because we need the env variables set by "source"
        awk < "${CI_WORK}/up1setenv.properties" > "${CI_ARTIFACTS_ENV}/up1setenv.properties" '
# pass-through any comments at top of file
p +0 == 0 && $0 !~ /^[A-Z0-9_]+ = ./    { print ; next ; }
# do not print this line until we know if the next line starts a new variable
    {
        p = 1
        if( $0 ~ /^[A-Z0-9_]+ = ./ )    c = ""
        else                            c = "\\"
    }
    { print buf c ; }
    { buf = $0 ; }
END { if( p +0 != 0 ) print buf ; }
'
    fi
    ;;
( * )
    # no upstream env found
    unset CI_UP1
    ;;
esac

        # end processing this file
ci_savenv
case "$ci_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
echo >&2 + : END ci_setenv.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac