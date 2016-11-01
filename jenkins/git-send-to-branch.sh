#! /bin/bash

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


# This script is kind of like a cherry-pick for directory trees
# instead of commits.  It will take the state of the specified
# directories and files at the point in time of a specific commit and
# drop those directories and files as a new commit on the current
# branch.


if [ "${#@}" -lt 2 -o "$1" == "-h" ]; then 
    echo "$0 [-h] <source commit-ish> <path>..."
    exit 1
fi

# This index must be empty since we'll be using it.
if git status --porcelain | grep -sq '^[MADRC ]\{2\}'; then
    echo "Please stash changes before running $0"
    exit 1
fi

src="$1"
shift

# Figure out the branch we're on.
dst=$(git symbolic-ref --short -q HEAD)
if [ -z "$dst" ]; then
    echo "Must have the HEAD of the destination branch checked out."
    exit 1
fi

# Prepare for pretty-printing the copied paths.
formatted_paths=$(for f in "$@"; do echo "    $f"; done)

# Add each of the paths from the source commit to the index.
for f in "$@"; do
    git diff-tree -p "$dst:" "$src:" -- "$f" | git apply
    git add -f --all "$f"
done

# Are we reverting to a prior state for the specified paths?
if git merge-base --is-ancestor "$src" "$dst"; then
    # Get the short commit-id for src since it is probably something like "HEAD~5"
    cid=$(git rev-parse --short "$src")
    git commit -s -F - >& /dev/null <<EOF
Revert specific paths on branch $dst

Paths reverted from $cid:
$formatted_paths
EOF
else
    git commit -s -F - >& /dev/null <<EOF
Copy specific paths from $src to $dst

Paths copied:
$formatted_paths
EOF
fi
