
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

# "Sandbox-test" build for prototyping Jenkins builds within the AllJoyn CI framework. 
# Derived from vfy-TC-u1404.

set -e +x
ci_job=sandbox-test.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

: get upstream build environment

ci_upsetenv 1
echo >&2 + : source up1setenv.sh
    # the following source, ci_savenv ops are standard for downstream jobs, but cannot be pushed into a function
source "${CI_ARTIFACTS_ENV}/up1setenv.sh"
ci_savenv

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

:
: START get upstream artifact
:

up1_zip=$( cd "${CI_UP1}" && ls -d "${CI_ARTIFACT_NAME_UP1}"*-dbg.zip | head -1 )
case "$up1_zip" in ( "" ) ci_exit 2 $ci_job, upstream 1 artifact "${CI_ARTIFACT_NAME_UP1}*-dbg.zip" not found ;; esac 
ci_unzip "${CI_UP1}/$up1_zip"
ci_mv ${up1_zip%.zip} alljoyn   # workaround for Windows/Cygwin
ci_showfs alljoyn

:
: START ajtcltest dbg
:

    # FIXME : tests should run a stand-alone alljoyn-daemon (Linux) or sample router (Windows), but they don't do either

source "${CI_COMMON}/cif_scons_vartags.sh"
source "${CI_COMMON}/cif_core_gtests.sh"

pushd alljoyn/core/ajtcl
    eval $( ci_thin_scons_vartags debug )
    ci_core_gtests $_os $_cpu debug on ajtcl
popd

set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"