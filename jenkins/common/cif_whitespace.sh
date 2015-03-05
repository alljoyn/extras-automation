
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

# function scans list of src files given on stdin, and performs the uncrustify whitespace check
#   cwd : top of Git workdir
#   argv1 : path to dir containing git info by rev, including list of files
#   argv2 : git rev
#   stdout : failed scan log file- any content on stdout means scan failed

echo >&2 + : BEGIN cif_whitespace.sh

ci_whitespace() {
    local _xet="$-"
    case "${CI_VERBOSE}" in ( [NnFf]* ) set +x ;; ( * ) set -x ;; esac

    : ci_whitespace "$@"

    local _revs="$1"
    shift

    rm -f "${CI_SCRATCH}/whitespace_patterns_include.txt"
    rm -f "${CI_SCRATCH}/whitespace_patterns_exclude.txt"

    : Ant-style case-insensitive fileset patterns to include source files in scan
    # no blanks, no comments, etc
    # at least one is required - eg, **/ will include everything (**/.git/ and **/.gitignore are excluded by default)

        # duplicate whitespace.py's internal selection criteria

    cat <<\Eof > "${CI_SCRATCH}/whitespace_patterns_include.txt" # duplicate the list generated internally by whitespace.py
**/*.c
**/*.cc
**/*.cpp
**/*.h
Eof

    : Ant-style case-insensitive fileset patterns to exclude source files from scan - ie, whitelist
    # no blanks, no comments, etc
    # at least one is required - eg, **/.git/** will never match

        # duplicate whitespace.py's internal selection criteria

    cat <<\Eof > "${CI_SCRATCH}/whitespace_patterns_exclude.txt"
**/alljoyn_java.h
**/Status.h
**/Internal.h
**/alljoyn_objc/**
**/ios/**
**/external/**
Eof

    : examine the last commit only
    local h hd
    for h in "$1"
    do
        hd="$_revs/$h"

        : reset Git workdir == target git rev
        git reset -q --hard "$h"
        git clean -fx

        rm -rf "${CI_SCRATCH}/src"
        mkdir -p "${CI_SCRATCH}/src"

        rm -f "$hd/whitespace_files_skipped.txt"
        rm -f "$hd/whitespace_files_list.txt"
        rm -f "$hd/whitespace_files_FAILED.txt"

        : select the source files wanted for this scan and copy them from src to scratch/src
        # redirect ci_scanset's stdout to keep our stdout clean
        ci_scanset < "$hd/files.txt" >&2 "${CI_SCRATCH}/whitespace_patterns_include.txt" "${CI_SCRATCH}/whitespace_patterns_exclude.txt" "$hd/whitespace_files_list.txt" "$hd/whitespace_files_skipped.txt"

        if test -s "$hd/whitespace_files_list.txt"
        then
            pushd "${CI_SCRATCH}/src" >&2
                : whitespace.py run in scratch/src
                python >&2 "${CI_COMMON}/whitespace.py" fix "${CI_COMMON}/ajuncrustify.cfg"
                : push the source files in scratch/src back to src - whitespace may have changed them
                cpio < "$hd/whitespace_files_list.txt" -pmdu "$OLDPWD"
            popd >&2
            : did scan fail?
            git diff --name-only > "$hd/whitespace_files_FAILED.txt"
            if test -s "$hd/whitespace_files_FAILED.txt"
            then
                : failed - report to stdout
                git diff
                echo
            else
                : passed - nothing to stdout - rm empty files_failed list
                rm -f "$hd/whitespace_files_FAILED.txt"
            fi
        else
            : no source files to scan - nothing to stdout
            echo >&2 + : INFO no source files in $h to scan for whitespace
        fi
    done

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
}

echo >&2 + : END cif_whitespace.sh
