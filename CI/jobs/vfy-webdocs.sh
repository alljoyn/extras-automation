
# #    Copyright (c) Open Connectivity Foundation (OCF) and AllJoyn Open
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

# Gerrit-verify build for AllJoyn Thin Core on any platform

    # FIXME 2015-02-05: Linux build should load up a daemon router,
    #       but the BusAttach test case was disabled in buildbot for some reason,
    #       so we do not need a daemon yet, so that code is deactivated

set -e +x
ci_job=vfy-webdocs.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x


:
:
cd "${WORKSPACE}"

ci_genversion webdocs ${GERRIT_BRANCH}  >  artifacts/manifest.txt

: INFO manifest

cat artifacts/manifest.txt

:
: START webdocs
:

pushd webdocs/scripts
    npm install
    cd ..
    node scripts/generate_docs.js
    node scripts/linkchecker.js || : ok
popd


set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"