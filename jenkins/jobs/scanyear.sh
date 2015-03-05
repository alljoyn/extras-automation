
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

# Gerrit build to check copyright year on changed src files (any Git).
# Since it does not matter what platform it runs on, we set up for a Ubuntu linux (not Windows).

set -ex

source "${CI_NODESCRIPTS_PART}.sh"
ci_me=$( basename "$0" )

:
: START $ci_me
:

case "${CI_VERBOSE}" in ( [NnFf]* ) ;; ( * ) ci_showfs ;; esac

cd "${WORKSPACE}"

ci_genversion src ${GERRIT_BRANCH}  >  manifest.txt

: INFO manifest

cat manifest.txt

pushd src
ci_showfs

: INFO List Files w source changes

git show --pretty="format:" --name-status HEAD > "${CI_ARTIFACTS}/files_list.txt"
cat "${CI_ARTIFACTS}/files_list.txt"

YYYY=`date +%Y`

: START Scan Modified files

awk < "${CI_ARTIFACTS}/files_list.txt" '
NF < 2           { next; }
$1 ~ "[^ADM]"    { next; }
$1 ~ "M"         { buf=$0 ; sub( "^" $1 "[\t ][\t ]*", "", buf ) ; print buf ; next ; }
' | grep -Ei '\.[chm]$|\.c[cs]$|\.cpp$|\.mm$|\.ino$|\.py$|\.sh$|\.java$|SConscript$|SConstruct$' | \
while read -r fn
do
  if [ -f "$fn" ]; then
    FES=`head -40 "$fn" | grep "Copyright.*[ ,-]$YYYY,\? AllSeen" | wc -l`
    if [ "$FES" != "1" ]; then
      : ERROR : "$fn"
      echo "$fn" fails copyright check. Regex for a valid copyright will be in the form of "Copyright.*[ ,-]$YYYY,\? AllSeen" for modified files >> "${CI_ARTIFACTS}/copyright-fail.log"
    else
      echo "$fn" passes copyright check >> "${CI_ARTIFACTS}/copyright-pass.log"
    fi
  fi
done

: START Scan Added files

awk < "${CI_ARTIFACTS}/files_list.txt" '
NF < 2           { next; }
$1 ~ "[^ADM]"    { next; }
$1 ~ "A"         { buf=$0 ; sub( "^" $1 "[\t ][\t ]*", "", buf ) ; print buf ; next ; }
' | grep -Ei '\.[chm]$|\.c[cs]$|\.cpp$|\.mm$|\.ino$|\.py$|\.sh$|\.java$|SConscript$|SConstruct$' | \
while read -r fn
do
  if [ -f "$fn" ]; then
    FES=`head -40 "$fn" | grep "Copyright (c) $YYYY,\? AllSeen" | wc -l`
    if [ "$FES" != "1" ]; then
      : ERROR : "$fn"
      echo "$fn" fails copyright check. Valid copyright regex "Copyright (c) $YYYY,\? AllSeen" for added files >> "${CI_ARTIFACTS}/copyright-fail.log"
    else
      echo "$fn" passes copyright check >> "${CI_ARTIFACTS}/copyright-pass.log"
    fi
  fi
done

: START status check

if [ -s "${CI_ARTIFACTS}/copyright-fail.log" ]; then
  ci_exit 2 $ci_job, see copyright-fail.log for details.
fi

: END $ci_me
