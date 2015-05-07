
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

# Gerrit-verify build for AllJoyn Std Core on all platforms except OSX


set -e +x
ci_job=vfy-alljoyn_core.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

source "${CI_COMMON}/cif_scons_vartags.sh"
source "${CI_COMMON}/cif_core_sconsbuilds.sh"

case "${CIAJ_OS}" in
( linux | win7 )
    source "${CI_COMMON}/cif_core_gtests.sh"
    source "${CI_COMMON}/cif_core_junits.sh"
    ;;
( android )
    : android unit tests : NOT YET
    ;;
esac

ci_savenv
case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac
echo >&2 + : STATUS preamble ok
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
set -x

:
:
cd "${WORKSPACE}"

ci_genversion alljoyn/core/alljoyn ${GERRIT_BRANCH}  >  alljoyn/manifest.txt
cp alljoyn/manifest.txt artifacts

:
: INFO manifest
:

cat alljoyn/manifest.txt

: START job

pushd alljoyn/core/alljoyn
    ci_core_sconsbuild "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}"
popd

case "${CIAJ_OS}" in
( linux | win7 )
    pushd alljoyn/core/alljoyn
        :
        : google tests
        :
        ci_core_gtests "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}" "${CIAJ_BR}" "${CIAJ_BINDINGS}"

        :
        : junit tests
        :
        ci_core_ready_junits "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}"
        ci_core_junits "${CIAJ_OS}" "${CIAJ_CPU}" "${CIAJ_VARIANT}" "${CIAJ_BR}"

    ##  case "${CIAJ_OS}" in
    ##  ( linux )
    ##      :
    ##      : START make samples
    ##      :
    ##      coresamples="build/${CIAJ_OS}/${CIAJ_CPU}/${CIAJ_VARIANT}/dist/cpp/samples"
    ##      ls -la "$coresamples"
    ##      list=$( find "$coresamples" -type f -name Makefile | sort )

    ##      echo "$list" | while read i
    ##      do
    ##          case "$i" in ( "" ) continue ;; esac
    ##          d=$( dirname "$i" )
    ##          pushd "$d"
    ##              :
    ##              : INFO $d
    ##              :
    ##              ls -la
    ##              make
    ##          popd
    ##      done
    ##      ;;
    ##  esac
    popd
    ;;
( android )
    : INFO android unit tests : NOT YET
    ;;
esac

:
:
set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"