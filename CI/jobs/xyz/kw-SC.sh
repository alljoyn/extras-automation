
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

# Klocwork Analysis for AllJoyn Std Core on any Xyzcity platform
# (except OSX which we do not support with Klocwork anyway)

set -e +x
ci_job=xyz/kw-SC.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

case "${CIAJ_VARIANT}" in
( debug )   export vartag=dbg ;;
( release ) export vartag=rel ;;
( * )       ci_exit 2 $ci_job, "CIAJ_VARIANT=${CIAJ_VARIANT}" ;;
esac

case "${CIAJ_CPU}" in
( *64 )     export cputag=x64 ;;
( *86 )     export cputag=x86 ;;
( arm )     export cputag=${CIAJ_CPU} ;;
esac

case "${CIAJ_BINDINGS}" in
( js,* | *,js,* | *,js )
    export GECKO_BASE=$( ci_natpath "${GECKO_BASE}" )
    export JSDOC_DIR=$( ci_natpath "${JSDOC_DIR}" )
    ;;
( * )
    unset GECKO_BASE
    unset JSDOC_DIR
    ;;
esac

case "${CIAJ_GTEST}" in
( [NnFf]* ) unset GTEST_DIR ;;
( * )       export GTEST_DIR=$( ci_natpath "${GTEST_DIR}" ) ;;
esac

source "${CI_COMMON}/${CI_SITE}/cif_kwbuild.sh"

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) verbose=0 ;; ( * ) verbose=1 ; ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

: INFO manifest

cat alljoyn/manifest.txt

:
: START kwinject
:
rm -rf "${CI_WORK}/klocwork"
mkdir -p "${CI_WORK}/klocwork/build"
mkdir -p "${CI_WORK}/klocwork/tables"

pushd alljoyn/core/alljoyn
    ci_kwinject --output "$( ci_natpath "${CI_WORK}/klocwork/build/spec.kw" )" \
        scons OS="${CIAJ_OS}" CPU="${CIAJ_CPU}" VARIANT="${CIAJ_VARIANT}" BINDINGS="${CIAJ_BINDINGS}" \
        BR="${CIAJ_BR}" POLICYDB="${CIAJ_POLICYDB}" ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION} \
        ${GECKO_BASE:+GECKO_BASE=}"$GECKO_BASE" \
        ${GTEST_DIR:+GTEST_DIR=}"$GTEST_DIR" \
        V=$verbose WS=off DOCS=none
    ci_showfs
popd

ls -la "${CI_WORK}/klocwork/build"

pushd "${CI_WORK}/klocwork/tables"
    ci_kwbuild ../build/spec.kw
    cp build.log "${CI_ARTIFACTS}/klocwork_build.log"
popd

:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"