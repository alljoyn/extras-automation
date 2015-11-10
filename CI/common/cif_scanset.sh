
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

# function selects src files wanted for next source scan, and copies them from cwd to work/src
#   cwd : top of Git workdir, e.g. src/
#   stdin : list of files Git changed, as from git show
#   argv1 : Ant "includesFile" : e.g., **/*.cpp, one pattern per line
#   argv2 : Ant "excludesFile" : e.g., **/sha2.h, one pattern per line, or empty file
#   argv3 : list of source files selected
#   argv4 : list of source files skipped by excludesFile (ie, whitelisted)

case "$cif_scanset_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_scanset_xet=cif_xet

echo >&2 + : BEGIN cif_scanset.sh

ci_scanset() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    : ci_scanset "$@"

    local _fullscan="${CI_FULLSCAN:-False}"

    case "$_fullscan" in
    ( [NnFf]* )
        : copy source files Git changed from cwd to work/src # reads am f from stdin
        local am f xit
        while read -r am f
        do
            case "$am" in
                ( "" | *[!ADM]* ) ;;
                ( *A*|*M* ) test -f "$f" && echo "$f" ;;
            esac
        done | cpio -pmdu "${CI_WORK}/src"
        ;;
    ( * )
        : copy ALL source files from cwd to work/src
        find . \( -type d \( -name .git -o -name .repo \) -prune \) -o \( -type f ! -type l -print \) | cpio -pmdu "${CI_WORK}/src"
        ;;
    esac

    echo >&2
    echo >&2 + : INFO includes / excludes
    echo >&2 + : include patterns
    cat >&2 "$1"
    echo >&2
    echo >&2 + : exclude patterns
    cat >&2 "$2"
    echo >&2

    : Ant scanset.xml to remove unwanted files from work/src
    ant -f "${CI_COMMON}/scanset.xml" -Dbasedir="${CI_WORK}/src" -Dscanset.includesFile="$1" -Dscanset.excludesFile="$2" -Dscanset.skipped="$4"

    : list of source files selected
    ( cd "${CI_WORK}/src" && find . -type f ! -type l ) | sed -e 's,^\..,,' | sort > "$3"

    : rm skipped_files list if empty - the unusual test below is because Ant always writes an LF even if no text
    xit=$( wc -c < "$4" )
    case "$xit" in
    ( 0 | 1 ) rm -f "$4" ;;
    esac

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
}

    # end processing this file

echo >&2 + : END cif_scanset.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac