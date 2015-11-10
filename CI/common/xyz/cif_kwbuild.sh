
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

# function performs Klocwork operations for any Xyzcity CI Klocwork analysis build
#   cwd : top of Klocwork tables directory
#   argv1 : buildspec file created by kwinject

case "$cif_xyz_kwbuild_xet" in
( "" )
    # cif_xet is undefined, so process this file
    export cif_xyz_kwbuild_xet=cif_xet

echo >&2 + : BEGIN xyz/cif_kwbuild.sh

ci_kwbuild() {
    local _xet="$-"
    local _xit=0

    : ci_kwbuild "$@"

    case "$1" in
    ( "" )
        ci_exit 2 ci_kwbuild, argv1 not found
        ;;
    ( * )
        local buildspec="$1"
        ls -la "$buildspec"
        ;;
    esac

    local klocwork_project=$( ci_klocwork_project )

    # Klocwork tools need to see the real HOME because kwlogin
    local _home_w=$( ci_natpath "${CI_FORCE_HOME}" )

    case "${CIXYZ_KLOCWORK_SOURCE_PROJECT}" in
    ( "" )
        ;;
    ( * )
        local klocwork_source_project="${CIXYZ_KLOCWORK_PROJECT_PREFIX}${CIXYZ_KLOCWORK_SOURCE_PROJECT}"

        :
        : START kwadmin duplicate project
        :

        : try to create "klocwork_project=$klocwork_project" from "klocwork_source_project=$klocwork_source_project"

        env HOME=${_home_w} \
        HOMEDRIVE=${CI_FORCE_HOMEDRIVE} \
        HOMEPATH=${CI_FORCE_HOMEPATH} \
        USERPROFILE=${CI_FORCE_USERPROFILE} \
        LOCALAPPDATA=${CI_FORCE_LOCALAPPDATA} \
            kwadmin --url "${CIXYZ_KLOCWORK_URL}/" duplicate-project "$klocwork_source_project" \
            "$klocwork_project" || : OK, maybe "$klocwork_project" exists already
        ;;
    esac

    :
    : START kwbuildproject
    :
    env HOME=${_home_w} \
    HOMEDRIVE=${CI_FORCE_HOMEDRIVE} \
    HOMEPATH=${CI_FORCE_HOMEPATH} \
    USERPROFILE=${CI_FORCE_USERPROFILE} \
    LOCALAPPDATA=${CI_FORCE_LOCALAPPDATA} \
        kwbuildproject --url "${CIXYZ_KLOCWORK_URL}/$klocwork_project" --tables-directory . "$( ci_natpath "$buildspec" )" || _xit=$?
    ci_showfs
    case "$_xit" in ( 0 ) ;; ( * ) : ERROR ci_kwbuild, kwbuildproject ; return 2 ;; esac

    :
    : START kwadmin load
    :
    env HOME=${_home_w} \
    HOMEDRIVE=${CI_FORCE_HOMEDRIVE} \
    HOMEPATH=${CI_FORCE_HOMEPATH} \
    USERPROFILE=${CI_FORCE_USERPROFILE} \
    LOCALAPPDATA=${CI_FORCE_LOCALAPPDATA} \
        kwadmin --url "${CIXYZ_KLOCWORK_URL}/" load --name "${BUILD_TAG}" "$klocwork_project" . || _xit=$?
    case "$_xit" in ( 0 ) ;; ( * ) : ERROR ci_kwbuild, kwadmin load ; return 2 ;; esac

    case "$_xet" in ( *x* ) set -x ;; ( * ) set +x ;; esac
}

    # end processing this file

echo >&2 + : END xyz/cif_kwbuild.sh
    ;;
( * )
    # ci_xet is already defined, so skip this file
    ;;
esac