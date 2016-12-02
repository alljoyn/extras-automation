
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


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