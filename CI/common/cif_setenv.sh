
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
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#    WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#    WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
#    AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
#    DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#    PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#    TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#    PERFORMANCE OF THIS SOFTWARE.

echo >&2 + : BEGIN cif_setenv.sh

# general ci shell functions

ci_showfs() {
    local _xet="$-"
    case "${CI_VERBOSE}" in
    ( [NnFf]* ) ;;
    ( * )
        case $# in
        ( 0 ) pwd ; ls -la ;;
        ( * )
            set +x
            for d ; do
                case "$d" in ( "" ) ;; ( * ) ( cd "$d" ; set -x ; pwd ; ls -la ) || : error ignored ;; esac
            done
            case "$_xet" in ( *x* ) set -x ;; esac
            ;;
        esac
        ;;
    esac
}
export -f ci_showfs     # if verbose then show current pwd and directory listing

ci_ck_fullpath() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac

    local _nl="
"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        case "${val}" in
        ( "" | *\ * | *\\* | *$_nl* | */ )
            echo >&2 ci_ck_fullpath : bad $name="'${val}'" ; _ok=False ;;
        ( /* )
            case "${val}" in ( //* ) ;; ( *//* ) echo >&2 ci_ck_fullpath : bad $name="'${val}'" ; _ok=False ;; esac
            ;;
        ( * )
            echo >&2 ci_ck_fullpath : bad $name="'${val}'" ; _ok=False ;;
        esac
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 ci_ck_fullpath ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}
export -f ci_ck_fullpath   # ck given full path is valid syntax

ci_ck_partpath() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac

    local _nl="
"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        case "${val}" in
        ( "" | *\ * | *\\* | *$_nl* | */ | /* | *//* )
            echo >&2 ci_ck_partpath : bad $name="'${val}'" ; _ok=False ;;
        esac
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 ci_ck_partpath ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}
export -f ci_ck_partpath   # ck given partial path is valid syntax

ci_ck_found() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac

    ci_ck_fullpath "$@"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        ls -dlL "$val" > /dev/null || {
            echo >&2 ci_ck_found : bad $name="'${val}'" ; _ok=False
        }
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 lci_ci_found ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}
export -f ci_ck_found       # ck given path is found

ci_upsetenv() {

    local _xet="$-"
    set +x

    echo >&2 + : ci_upsetenv "$@"

    local up
    case "$1" in ( [1-9] ) up=$1 ;; ( * ) up=1 ;; esac

    export CI_UP${up}="${CI_SCRATCH}/up${up}/artifacts"

    ls -dl "${CI_UP1}/env/setenv.sh" || ci_exit 2 ci_upsetenv, upstream $up artifact env/setenv.sh not found

    mkdir -p "${WORKSPACE}/work" || : ok
    rm -f "${WORKSPACE}/work/ci_upsetenv.awk" "${WORKSPACE}/work/ci_upsetenv.txt"

    cat << \EoF > "${WORKSPACE}/work/ci_upsetenv.awk"
    # q == 0 means remember these variables names, do not write
    # q != 0 means rewrite as "_UP1" variables
    # p != 0 means write continuation line(s) if any

    # if line does not start with "declare -" then it is a continuation line

$0 ~ "^EoS$"    { q=1; next; }

$1 " " $2 !~ /^declare -[^ ]+$/     {
        if( p+0 != 0 && q+0 != 0 ) print; next
    }

    # all lines after this look like "declare -x name=value"

    {
        p=0; v=$3 ""; sub( "=.*", "", v ); l=length( v ); u=toupper( v )
    }

    # ignore variable if name less than 3 chars long

l+0 < 3     { next; }

    # ignore variable if name does not start with letter

u "" ~ /^[^A-Z]/    { next; }

    # ignore variable if name has illegal (for shell) character

u "" ~ /^[^A-Z0-9_]/    { next; }

    # ignore these

u "" ~ /^CIF*_.*XET$/   { next; }
u "" ~ /^CIF*_.*ENV$/   { next; }

    # remember selected variable names

v "" ~ /^(CIAJ|GIT|GERRIT)_/ && v "" !~ /_UP[1-9]$/ {
        if( q+0 == 0 ) q0v[ v "" ] = 1
        else           q1v[ v "" ] = 1
    }

    # only q==1 after this

q+0 == 0    { next; }

    # for selected variables, write $0 with "_UP1" added to variable name

( u "" ~ /^(CI[A-Z]*|BUILD|HUDSON|JENKINS|JOB|NODE|GIT|GERRIT)_/ && u "" !~ /_UP[1-9]$/ ) || ( u "" ~ /^(DESCRIPTION_SETTER_DESCRIPTION|SERVICE_ID)$/ ) {
        sub( "^declare -[^ ]+", "export" ) ; sub( "=", "_UP" up "=" ) ; p=1; print; next
    }

END {
        # carry selected variables from upstream job into downstream job
        buf=""
        for ( v in q1v ) {
            if ( q0v[ v "" ]+0 == 0 ) {
                vup=v ; sub( "$", "_UP" up, vup ) ; print "export " v "=$" vup ; buf = buf "\n" v " = $" vup ;
            }
        }
        if ( buf "" != "" ) {
            print "cat <<eof" ; print "#" ; print "# Jenkins EnvInject properties" ; print "#" buf ;
            print "eof"
        }
    }
EoF
    ci_declare_env > "${WORKSPACE}/work/ci_upsetenv.txt"
    echo "EoS" | cat -- "${WORKSPACE}/work/ci_upsetenv.txt" - "${CI_UP1}/env/setenv.sh" | \
        awk > "${CI_ARTIFACTS_ENV}/up${up}setenv.sh" -v up=$up -f "${WORKSPACE}/work/ci_upsetenv.awk"

    ls -dl "${CI_ARTIFACTS_ENV}/up${up}setenv.sh"

    case "$_xet" in ( *x* ) set -x ;; esac
}
export -f ci_upsetenv       # stdin-stdout filter, selects variables for downstream job from upstream jobs setenv.sh file

ci_zip_simple_artifact() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac
    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"

    :
    : ci_zip_simple_artifact "$@"
    :

    local from zip work to

    # $1 = from = full path to starting location
    # $2 = zip  = simple file name of zip file to create, not incl the .zip
    # $3+ = optional sub-paths within "from" to include in "zip".zip
    case "$1" in
    ( "" ) ci_exit 2 ci_zip_simple_artifact, "argv1=$1 is empty" ;;
    ( * )   from=$1 ;;
    esac
    case "$2" in
    ( "" | */* ) ci_exit 2 ci_zip_simple_artifact, "argv2=$2 is empty or not allowed" ;;
    ( * )   zip=$2 ;;
    esac
    shift 2
    case "$1" in
    ( "" )  set -- . ;;
    ( /* )  ci_exit 2 ci_zip_simple_artifact, "argv3=$1 is not allowed" ;;
    esac

    work=${CI_SCRATCH_ARTIFACTS}/$zip
    to=${CI_ARTIFACTS}/$zip.zip

    rm -rf "$work" "$to"    || : error ignored
    mkdir -p "$work"        || : error ignored

    set -ex
    : ci_zip_simple_artifact: "copy $@ from=$from to the working tree"
    pushd "$from" || return $?
        ci_showfs
        tar -cf - "$@" | ( cd "$work" && tar -xf - )
    popd

    : ci_zip_simple_artifact: "archive the working tree to zip=$zip"
    pushd "$work/.."
        ci_showfs
        ci_zip "$to" "$zip"
    popd

    rm -rf "$work"

    date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
    case "$_xet" in ( *x* ) set -x ;; esac
}
export -f ci_zip_simple_artifact    # archives one "simple" build artifact in a standard way

    # wrapper functions for Windows v. *nix

case "${CI_SHELL_W}" in
( "" )                  # non-Windows

    ci_natpath() {          # dummy path conversion
        echo "$@"
    }

    ci_mv() {               # dummy mv -f
        mv -f "$@"
    }

    ci_genversion() {       # run genversion.py with parameters
        # argv1= path to git workspace; argv2= git branch, optional: default is branch seen in git workspace
        python "${CI_GENVERSION_PY}" "$1" $2
    }

    ci_test_harness() {      # run test_harness.py with parameters
        # argv1= name of gtest executable file
        # argv2= test_harness config file
        # argv3= log file to be written (console output also appears on stdout)
        # argv4= optional path to directory containing argv1
        local xit=0
        local path_to_gtestfile=${4:-.}
        :
        : START test_harness "$@"
        :
        time python "${CI_TEST_HARNESS_PY}" -c "$2" -t $1 -p "$path_to_gtestfile" < /dev/null | tee "$3"
        tail -10 "$3" | grep -q "exiting with status 0" || {
            xit=1
            :
            : FAILURE test_harness $1
            :
        }
        return $xit
    }

    ci_slash_1_2() {        # only on Windows
        ci_exit 2 ci_slash_1_2 only on Windows
    }

    ci_scons() {            # dummy scons
        local _xet="$-"
        case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
        ci_savenv

        local minusk
        case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) minusk="" ;; ( * ) minusk=-k ;; esac

        case "$_xet" in ( *x* ) set -x ;; esac
        scons "$@" $minusk
    }

    ci_zip() {              # dummy zip
        zip -q -r "$@"
    }

    ci_unzip() {            # dummy unzip
        unzip -q "$@"
    }
    ;;

( [A-Za-z]:\\*sh* )     # Windows with msysgit or cygwin

    ci_natpath() {          # natpath converts given path to Windows form
        local _xet="$-"
        set +x
        local _buf
        while true; do
            case $# in ( 0 ) break ;; esac
            case "$1" in
            ( /[A-Za-z][\\/]* ) # rewrite absolute path like /c/* (drive letter) to 'C:\*'
                _buf=$( echo "$1" | sed -e 's,^/\(.\)/,\1:\\,' -e 's,/,\\,g' )
                echo "${_buf}"
                ;;
            ( /[A-Za-z]   )     # rewrite absolute path like /c   (drive letter) to 'C:\'
                _buf=$( echo "$1" | sed -e 's,^/\(.\),\1:\\,' )
                echo "${_buf}"
                ;;
            (  //* )            # rewrite UNC path like //filer/* to '\\filer\*'
                echo "$1" | sed -e 's,/,\\,g'
                ;;
            (  /* )             # rewrite native path like /home/* (msys native) to 'C:\msys\root\home\*' (for example)
                _buf=$( echo "${CI_SHELL_W}" | sed -e 's,\\bin\\[^\\]*sh[^\\]*$,,' -e 's,\\,\\\\,g' )
                echo "$1" | sed -e "s,^,${_buf}," -e 's,/,\\,g'
                ;;
            ( * )               # assume partial path
                echo "$1" | sed -e 's,/,\\,g'
                ;;
            esac
            shift
        done
        case "$_xet" in ( *x* ) set -x ;; esac
    }

    ci_mv() {               # ci_mv implements mv -f with workarounds for balky Windows/Cygwin file systems
        local _xet="$-"
        set +x

        case $# in
        ( 2 )
            case "$1" in ( "" ) ci_exit 2 argv1 not found, ci_mv "$@" ;; esac
            case "$2" in ( "" ) ci_exit 2 argv2 not found, ci_mv "$@" ;; esac
            ;;
        ( * )
            ci_exit 2 exactly 2 arguments, ci_mv "$@"
            ;;
        esac

        local i
        ls -d "$1" > /dev/null || ci_exit 2 ci_mv "$1" not found
        if ls -d "$2" > /dev/null 2>&1
        then
            for i in 1 2 3 4 5; do ls -d "$2" > /dev/null 2>&1 || break && rm -rf "$2" || sleep 2; done
            ls -d "$2" 2> /dev/null && ci_exit 2 ci_mv, failed rm -rf "$2"
        fi

        for i in 1 2 3 4 5; do ls -d "$2" > /dev/null 2>&1 && break || mv -f "$1" "$2" || sleep 2; done
        ls -d "$2" > /dev/null || ci_exit 2 ci_mv, failed mv "$1" "$2"

        case "$_xet" in ( *x* ) set -x ;; esac
    }

    ci_genversion() {           # run genversion.py with parameters
        # argv1= path to git workspace; argv2= git branch, optional: default is branch seen in git workspace
        python "$( ci_natpath "${CI_GENVERSION_PY}" )" "$( ci_natpath "$1" )" $2
    }

    ci_test_harness() {      # run test_harness.py with parameters
        # argv1= name of gtest executable file
        # argv2= test_harness config file
        # argv3= log file to be written (console output also appears on stdout)
        # argv4= optional path to directory containing argv1
        local xet=$-
        set +x
        local xit=0
        local test_harness=$( ci_natpath "${CI_TEST_HARNESS_PY}" )
        local config_file=$( ci_natpath "$2" )
        local path_to_gtestfile=$( ci_natpath "${4:-.}" )
        case "$xet" in ( *x* ) set -x ;; esac
        :
        : START test_harness $vartag "$@"
        :
        time python "$test_harness" -c "$config_file" -t $1 -p "$path_to_gtestfile" < /dev/null | tee "$3"
        tail -10 "$3" | grep -q "exiting with status 0" || {
            xit=1
            :
            : FAILURE ci_test_harness $1
            :
        }
        return $xit
    }

    export CI_SLASH_1_2=
    for i in "/" "//"
    do
        if j=$( cmd.exe ${i}C echo test < /dev/null )
        then
            case "$j" in ( *test* ) CI_SLASH_1_2=$i ; break ;; esac
        fi
    done
    case "${CI_SLASH_1_2}" in ( "" ) ci_exit 2 ci_setenv.sh, "no valid CI_SLASH_1_2" ;; esac

    ci_slash_1_2() {
        echo -n "${CI_SLASH_1_2}"
    }

    ci_scons() {                # run scons via cmd shell and setenv.bat
        local _xet="$-"
        case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
        ci_savenv

        local minusk
        case "${CI_KEEPGOING}" in ( "" | [NnFf]* ) minusk="" ;; ( * ) minusk=-k ;; esac
        cp "${CI_ARTIFACTS_ENV}/ci_setenv.bat" "${CI_ARTIFACTS_ENV}/ci_scons.bat"
        (
            echo "@echo on"
            case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) echo set ;; esac
            echo call scons "$@" $minusk
        ) | sed -e 's,$,\r,' >> "${CI_ARTIFACTS_ENV}/ci_scons.bat"

        case "$_xet" in ( *x* ) set -x ;; esac
        cmd.exe ${CI_SLASH_1_2}C "$( ci_natpath "${CI_ARTIFACTS_ENV}/ci_scons.bat" )"
    }

    if type zip.exe
    then
        ci_zip() {              # dummy zip
            zip -q -r "$@"
        }
    else
        ci_zip() {                  # use jar as zip
            local _xet="$-"
            case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
            local _argv=""
            local _jar="jar -cMf"
            for _argv in "$@"
            do
                _jar="$_jar $( ci_natpath "$_argv" )"
            done

            # override local $WORKSPACE/tmp to make sure jar cannot try to zip up its own TMP dir,
            # especially from common/archive-workspace.sh
            local _tmp_w=$( ci_natpath "${CI_FORCE_TMP}" )

            case "$_xet" in ( *x* ) set -x ;; esac

            env TMP=${_tmp_w} \
                TMPDIR=${_tmp_w} \
                TEMP=${CI_FORCE_TEMP} \
                $_jar
        }
    fi

    if type unzip.exe
    then
        ci_unzip() {            # dummy unzip
            unzip -q "$@"
        }
    else
        ci_unzip() {                # use jar as unzip
            local _xet="$-"
            case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
            local _argv=""
            local _jar="jar -xf"
            for _argv in "$@"
            do
                _jar="$_jar $( ci_natpath "$_argv" )"
            done
            case "$_xet" in ( *x* ) set -x ;; esac
            $_jar
        }
    fi

        # convert WORKSPACE variable from Windows form

	export WORKSPACE=$( echo "${WORKSPACE}" | sed -e 's,^\([A-Za-z]\):\\,/\1/,' -e 's,\\,/,g' )
    ;;

( * )   # some unexpected string
    ci_exit 2 ci_setenv.sh, "CI_SHELL_W=${CI_SHELL_W}"
    ;;
esac

export -f ci_natpath        # convert Jenkins/posix path to "native"
export -f ci_genversion     # run genversion.py
export -f ci_test_harness   # run test_harness.py
export -f ci_slash_1_2      # ci_slash_1_2 gives you the right number of slashes for a command line switch.
                                # Explained:
    # MSysGit attempts to auto-convert *nix paths as command line parameters to Windows paths.
    # MSysGit therefore needs an extra slash to tell the difference between a command line
    # switch like "/C" v. a path like "/C" - ie, a drive letter. For example, you have to say
    #   cmd.exe //C (whatever) in MSysGit.
    # Cygwin bash does not autoconvert anything or look for extra slashes, so you have to say
    #   cmd.exe /C (whatever) instead.
export -f ci_scons          # run scons in "native" environment
export -f ci_zip            # run basic zip
export -f ci_unzip          # run basic unzip

echo >&2 + : END cif_setenv.sh