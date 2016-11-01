
# Copyright (c) 2016 Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright 2016 Open Connectivity Foundation and Contributors to
#    AllSeen Alliance. All rights reserved.
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

# Jenkins build environment and workspace setup

ci_xet="$-"

case "$CI_VERBOSE" in ( [NnFf]* ) set +x ;; ( * ) ;; esac

unset ENV BASH_ENV
export PATH=/opt/bin:/usr/local/bin:/usr/bin:/bin

ci_exit() {
    set +ex
    local _xit
    case "$1" in ( [0-9] | [1-9][0-9] | [1-9][0-9][0-9] ) _xit=$1 ; shift ;; ( * ) _xit=2 ;; esac
    case $_xit in ( 0 ) ;; ( * ) echo >&2 "+ : ERROR $@" ;; esac

    case "$ci_xet" in
    ( *i* )
        # interactive shell
        echo > /dev/tty "called exit $@ : waiting for you to interrupt"
        read < /dev/tty junk
        ;;
    ( * )
        # script
        exit $_xit
        ;;
    esac
}

# functions: zip and unzip

ci_zip() {
    # jar -cMf
    zip -q -r "$@"
}
ci_unzip() {
    # jar -xf
    unzip -q "$@"
}

# functions: show file system, environment variables

ci_showfs() {
    local _xet="$-"
    case "$CI_VERBOSE" in
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
ci_showenv() {
    case "$CI_VERBOSE" in
    ( [NnFf]* ) ;;
    ( * ) date ; env | sort ;;
    esac
}

# functions: check syntax of absolute paths, partial paths

lci_ck_fullpath() {
    local _xet="$-"
    case "$CI_VERBOSE" in ( [NnFf]* ) set +x ;; ( * ) ;; esac

    local _nl="
"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        case "${val}" in
        ( "" | *\ * | *\\* | *$_nl* | *//* | */ )
            echo >&2 lci_ck_fullpath : bad $name="'${val}'" ; _ok=False ;;
        ( /* )
            ;;
        ( * )
            echo >&2 lci_ck_fullpath : bad $name="'${val}'" ; _ok=False ;;
        esac
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}
lci_ck_partpath() {
    local _xet="$-"
    case "$CI_VERBOSE" in ( [NnFf]* ) set +x ;; ( * ) ;; esac

    local _nl="
"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        case "${val}" in
        ( "" | *\ * | *\\* | *$_nl* | *//* | */ | /* )
            echo >&2 lci_ck_partpath : bad $name="'${val}'" ; _ok=False ;;
        esac
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}
lci_ck_found() {
    local _xet="$-"
    case "$CI_VERBOSE" in ( [NnFf]* ) set +x ;; ( * ) ;; esac

    lci_ck_fullpath "$@"
    local _ok=True
    local name val
    while test $# -gt 0 ; do
        name=$1
        shift
        eval val="\${$name}"
        ls -dlL "$val" > /dev/null || {
            echo >&2 lci_ck_found : bad $name="'${val}'" ; _ok=False
        }
    done
    case "$_ok" in ( True ) ;; ( * ) ci_exit 2 ;; esac
    case "$_xet" in ( *x* ) set -x ;; esac
}

# ck existing env variables

lci_ck_partpath CI_JOB_TYPE CI_NODE_TYPE CI_SRC_AUTOMATION
lci_ck_found WORKSPACE

# set some common env variables

export WCI_JENKINS=${WORKSPACE}/${CI_SRC_AUTOMATION}/jenkins
export WCI_JOB_SCRIPTS=$WCI_JENKINS/ci_job_types/${CI_JOB_TYPE}
export WCI_NODE_SCRIPTS=$WCI_JENKINS/ci_node_types/${CI_NODE_TYPE}
export WCI_GENVERSION_PY=$WCI_JENKINS/common/genversion.py

lci_ck_found WCI_JENKINS WCI_JOB_SCRIPTS WCI_NODE_SCRIPTS WCI_GENVERSION_PY

export WCI_SCRATCH=${WORKSPACE}/scratch
export WCI_ARTIFACTS=${WORKSPACE}/artifacts
export WCI_ARTIFACTS_WORK=${WCI_SCRATCH}/artifacts

lci_ck_fullpath WCI_SCRATCH WCI_ARTIFACTS WCI_ARTIFACTS_WORK

export HOME=${WORKSPACE}/home
export TMP=${WORKSPACE}/tmp
export TEMP=$TMP
export TMPDIR=$TMP

(
    set +e
    mkdir -p $HOME 2>/dev/null
    mkdir -p $TMP 2>/dev/null
    mkdir -p $WCI_SCRATCH 2>/dev/null
    mkdir -p $WCI_ARTIFACTS 2>/dev/null
    mkdir -p $WCI_ARTIFACTS_WORK 2>/dev/null
) || : error ignored

case "$_xet" in ( *x* ) set -x ;; esac
