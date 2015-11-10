
# Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
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

# Xyzcity-specific Jenkins build environment and workspace folder setup

case "$ci_xet" in
( "" )
    # ci_xet is undefined, so process this file

echo >&2 + : BEGIN xyz/ci_setenv.sh

source "${CI_COMMON_PART}/ci_setenv.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

# function returns a complete Klocwork project name
# on Xyzcity KW server, according to current naming convention there

ci_klocwork_project() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    : ci_klocwork_project "$@"

    case "${CIXYZ_KLOCWORK_PROJECT_BASENAME}" in
    ( "" )
        ci_exit 2 ci_klocwork_project, "CIXYZ_KLOCWORK_PROJECT_BASENAME not found"
        ;;
    ( * )
        local basename="${CIXYZ_KLOCWORK_PROJECT_BASENAME}"
        ;;
    esac
    case "${CIXYZ_KLOCWORK_URL}" in ( "" ) ci_exit 2 ci_klocwork_project, "CIXYZ_KLOCWORK_URL not found" ;; esac

    local branch="${GERRIT_BRANCH}"
    local prefix="${CIXYZ_KLOCWORK_PROJECT_PREFIX}"
    local project

    case "$branch" in
    ( feature/security2.0 )
        project="${prefix}${basename}.${branch#feature/}"
        ;;
    ( */* )
        project="${prefix}${basename}.$( echo "${branch}" | sed -e 's,/,_,g' )"
        ;;
    ( * )
        project="${prefix}${basename}.$branch"
        ;;
    esac

    echo "$project"

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
}
export -f ci_klocwork_project

    # wrapper functions for Windows v. *nix

case "${CI_SHELL_W}" in
( "" )                  # non-Windows

    ci_kwinject() {            # Klocwork kwinject
        kwinject "$@"
    }

    ci_iarbuild() {            # only on Windows
        ci_exit 2 ERROR ci_iarbuild only on Windows
    }
    ;;

( [A-Za-z]:\\*sh* )     # Windows with msysgit or cygwin

    ci_kwinject() {            # run kwinject via cmd shell and setenv.bat
        local _xet="$-"
        case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
        cp "${CI_ARTIFACTS_ENV}/ci_setenv.bat" "${CI_ARTIFACTS_ENV}/ci_kwinject.bat"
        (
            echo "@echo on"
            case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) echo set ;; esac
            echo kwinject "$@"
        ) | sed -e 's,$,\r,' >> "${CI_ARTIFACTS_ENV}/ci_kwinject.bat"
        case "$_xet" in ( *x* ) set -x ;; esac
        cmd.exe ${CI_SLASH_1_2}C "$( ci_natpath "${CI_ARTIFACTS_ENV}/ci_kwinject.bat" )"
    }

    ci_iarbuild() {            # run iarbuild via cmd shell and setenv.bat
        local _xet="$-"
        case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; esac
        cp "${CI_ARTIFACTS_ENV}/ci_setenv.bat" "${CI_ARTIFACTS_ENV}/ci_iarbuild.bat"
        (
            echo set HOME="$( ci_natpath "${CI_FORCE_HOME}" )"
            echo set HOMEDRIVE="${CI_FORCE_HOMEDRIVE}"
            echo set HOMEPATH="${CI_FORCE_HOMEPATH}"
            echo set USERPROFILE="${CI_FORCE_USERPROFILE}"
            echo set LOCALAPPDATA="${CI_FORCE_LOCALAPPDATA}"
            echo "@echo on"
            case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) echo set ;; esac
            echo "$( ci_natpath "$IARBUILD" )" "$@"
        ) | sed -e 's,$,\r,' >> "${CI_ARTIFACTS_ENV}/ci_iarbuild.bat"
        case "$_xet" in ( *x* ) set -x ;; esac
        cmd.exe ${CI_SLASH_1_2}C "$( ci_natpath "${CI_ARTIFACTS_ENV}/ci_iarbuild.bat" )"
    }
    ;;

( * )   # some unexpected string
    ci_exit 2 xyz/ci_setenv.sh, "CI_SHELL_W=${CI_SHELL_W}"
    ;;
esac

export -f ci_kwinject       # Klocwork kwinject
export -f ci_iarbuild       # iarbuild

# TEST_TOOLS is probably going to change, anyway
ci_ck_partpath CIXYZ_TEST_TOOLS_PART
export CIXYZ_TEST_TOOLS=${WORKSPACE}/${CIXYZ_TEST_TOOLS_PART}


        # end processing this file
ci_savenv
case "$ci_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
echo >&2 + : END xyz/ci_setenv.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac