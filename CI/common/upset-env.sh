
# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


# processes environment received from upstream build

: force Verbose=False
export CI_VERBOSE=False
set -e +x
ci_job=upset-env.sh
ci_job_xit=0
echo >&2 + : BEGIN $ci_job
echo >&2 + : START preamble
source "${CI_NODESCRIPTS_PART}.sh"

echo >&2 + : STATUS preamble ok
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
set -x
:
: BUILD DESCRIPTION : "${DESCRIPTION_SETTER_DESCRIPTION_UP1%<br/>*}"
:
set +x
date "+TIMESTAMP=%Y/%m/%d-%H:%M:%S"
echo >&2 + : STATUS $ci_job exit $ci_job_xit
exit "$ci_job_xit"