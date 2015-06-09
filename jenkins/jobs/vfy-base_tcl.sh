
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

# Gerrit-verify build for AllJoyn Thin Services on any platform

set -e +x
ci_job=vfy-base_tcl.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

eval _t="${CI_ARTIFACT_NAME}"
export CI_ARTIFACT_NAME=$_t
eval _t="${CIAJ_CORE_GITREV}"
export CIAJ_CORE_GITREV=$_t

source "${CI_COMMON}/cif_scons_vartags.sh"

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
set -x


case "${CI_VERBOSE}" in ( [NnFf]* ) _verbose=0 ;; ( * ) _verbose=1 ;; esac

case "$( uname )" in
( Linux )
    _os=linux
    _cpu=$( uname -m )
    ;;
( Darwin )
    _os=darwin
    _cpu=$( uname -m )
    ;;
( CYGWIN* | MINGW* )
    _os=win7
    case "$( uname -m )" in ( i686 | *64 ) _cpu=x86_64 ;; ( *86 ) _cpu=x86 ;; esac
    ;;
( * )
    ci_exit 2 $ci_job, trap uname="$( uname -a )"
    ;;
esac

case "$( uname )" in
( Linux )
    _uncrustify=$( uncrustify --version ) || : ok
    case "$_uncrustify" in
    ( uncrustify* )
        case "${GERRIT_BRANCH}/$_uncrustify" in
        ( RB14.12/uncrustify\ 0.61* )
            _ws=off
            :
            : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
            :
            ;;
        ( RB14.12/uncrustify\ 0.57* )
            _ws=detail
            ;;
        ( */uncrustify\ 0.61* )
            _ws=detail
            ;;
        ( * )
            _ws=off
            :
            : WARNING $ci_job, found "$_uncrustify", have alljoyn branch="${GERRIT_BRANCH}" : skipping Whitespace scan
            :
            ;;
        esac
        ;;
    ( * )
        _ws=off
        :
        : WARNING $ci_job, uncrustify not found: skipping Whitespace scan
        :
        ;;
    esac
    ;;
( * )
    _ws=off
    ;;
esac

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/services/base_tcl ${GERRIT_BRANCH}  >  alljoyn/manifest.txt

:
: START extra Gits
:

case "${GIT_URL}" in
( */services/base_tcl.git )   b=${GIT_URL%/services/base_tcl.git} ;;
( */services/base_tcl )       b=${GIT_URL%/services/base_tcl} ;;
( * )   ci_exit 2 $ci_job, trap "GIT_URL=${GIT_URL}" ;;
esac
for p in core/ajtcl ; do

    :
    : clone $p
    :

    rm -rf alljoyn/$p ; git clone "$b/$p.git" alljoyn/$p

    case $p in
    ( core/ajtcl )  r="${CIAJ_CORE_GITREV}" ;;
    esac

    pushd alljoyn/$p
        case "$r" in ( "" ) ;; ( * ) git checkout "$r" || : WARNING "$r not found $p.git, using master." ;; esac
        git log -1
        ci_showfs
    popd
    ci_genversion alljoyn/$p >> alljoyn/manifest.txt
done

:
: INFO manifest
:

cp alljoyn/manifest.txt artifacts
cat alljoyn/manifest.txt

:
:
cd "${WORKSPACE}"

rm  -rf "${CI_SCRATCH}/ajtcl.tar"   "${CI_SCRATCH}/base_tcl.tar"
tar -cf "${CI_SCRATCH}/ajtcl.tar"    alljoyn/core/ajtcl
tar -cf "${CI_SCRATCH}/base_tcl.tar" alljoyn/services/base_tcl

for _variant in release debug
do

    rm -rf alljoyn/core/ajtcl alljoyn/services/base_tcl
    tar -xf "${CI_SCRATCH}/ajtcl.tar"
    tar -xf "${CI_SCRATCH}/base_tcl.tar"

    eval $( ci_scons_vartags $_os $_cpu $_variant )

    :
    : START build ajtcl $_variant
    :

    pushd alljoyn/core/ajtcl
    ci_scons V=$_verbose WS=off VARIANT=$_variant ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
        ci_showfs
    popd

    if ls -ld alljoyn/services/base_tcl/SConstruct
    then
        :
        : START build base_tcl $_variant
        :

        pushd alljoyn/services/base_tcl
            ci_scons V=$_verbose WS=$_ws EXCLUDE_ONBOARDING=yes VARIANT=$_variant ${CIAJ_MSVC_VERSION:+MSVC_VERSION=}${CIAJ_MSVC_VERSION}
            ci_showfs
        popd
        _ws=off
    else
        ci_exit 2 "$ci_job, SConstruct not found in base_tcl. Is tc_reorg present?"
    fi

    :
    : START artifacts
    :

    cd "${WORKSPACE}"

    zip=${CI_ARTIFACT_NAME}-$_os-$cputag-sdk-$vartag
    work=${CI_ARTIFACTS_SCRATCH}/$zip
    to=${CI_ARTIFACTS}/$zip.zip

    rm -rf "$work" "$to"    || : error ignored
    mkdir -p "$work"        || : error ignored

    cp alljoyn/manifest.txt "$work"

    cp -rp alljoyn/services/base_tcl/dist/* "$work"

    pushd "$work/.."
        : INFO show $zip.zip
        find "$zip" -type f -ls
        ci_zip "$to" "$zip"
    popd

    rm -rf "$work"
done
:
:
set +x
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"
