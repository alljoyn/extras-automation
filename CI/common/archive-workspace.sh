
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# archives the entire workspace on any platform, except for "artifacts" and "scratch"

: force Verbose=False
export CI_VERBOSE=False
set -e +x
ci_job=archive-workspace.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

echo >&2 + : STATUS preamble ok
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
set -x
:
: START archive-workspace
:
case "${BUILD_TAG}" in
( "" )
    ci_exit 2 $ci_job, missing BUILD_TAG
    ;;
( * )
    cd "${WORKSPACE}"
    mkdir -p artifacts 2>/dev/null || : ok
    rm -f "artifacts/${BUILD_TAG}.zip"

    _list=$(
        set +x
        ls -1a | grep -iv -e '^artifacts$' -e '^scratch$' -e '^\.$' -e '^\.\.$' | while read -r f
        do
            echo "'$f'"
        done
    )
    case "$_list" in
    ( "" )
        echo >&2 "workspace is empty, except for artifacts"
        ;;
    ( * )
        eval ci_zip "artifacts/${BUILD_TAG}.zip" $_list
        echo >&2 "archived workspace as artifacts/${BUILD_TAG}.zip"
        ;;
    esac
    ;;
esac

set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"