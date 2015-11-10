#!/usr/bin/env python2.6

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
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#    WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#    WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
#    AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
#    DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#    PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#    TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#    PERFORMANCE OF THIS SOFTWARE.

import json
import threading
import Queue
import os
import os.path
import re
import signal
import subprocess
import sys
import time

def fetchpush( git, processors=None ):

    if processors:
        processors.put(True)

# fetch a given git project from remote "allseen" and push it to the remote "xyzcity"
# the project must already exist on both servers and in the "gits" subdirectory

    allseen_url = 'ssh://xyzbuild@git.allseenalliance.org:29418/%s.git' % (git)
    xyzcity_url = 'ssh://xyzbuild@git-xyzcity:29418/allseen/%s.git' % (git)

    prescript= '''
exec >> "logs/%(git)s.log" 2>&1
date "+%%n%%Y-%%m-%%d %%H:%%M:%%S %(fetchpush)s(%(git)s): START%%n"
set -x
cd "gits/%(git)s.git"
'''

    postscript= '''
set +x
date "+%%n%%Y-%%m-%%d %%H:%%M:%%S %(fetchpush)s(%(git)s): OK%%n"
'''

# fetch

    retcode = subprocess.call( [ 'bash', '-e', '-c', prescript % {'fetchpush':'fetch', 'git':git,} + '''
git fetch --prune --no-tags "%(url)s" "+refs/heads/*:refs/heads/*"
git fetch --prune           "%(url)s" "+refs/tags/*:refs/tags/*"
set +x
date >&2 "+%%Y-%%m-%%d %%H:%%M:%%S"
git show-ref | while read i j
do
    case "$j" in
    ( refs/heads/xyz | refs/tags/xyz | refs/heads/xyz/* | refs/tags/xyz/* )
        ( set -x ; git update-ref -d "$j" )
        ;;
    esac
    set +x
done
''' % {'url':allseen_url,} + postscript % {'fetchpush':'fetch', 'git':git}, ] )

    if retcode:
        sys.stderr.write( '%s fetch(%s): error=%d\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git,retcode) )
    else:
        sys.stderr.write( '%s fetch(%s): OK\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git) )
    sys.stderr.flush()

# push

    retcode = subprocess.call( [ 'bash', '-e', '-c', prescript % {'fetchpush':'push', 'git':git,} + '''
set +x
xit=0
t=$( set -x ; git push --prune "%(url)s" "+refs/heads/*:refs/heads/*" 2>&1 ) || xit=$?
echo >&2 "$t"
date >&2 "+%%Y-%%m-%%d %%H:%%M:%%S"
case $xit in
( 0 )
    ;;
( * )
    echo "$t" | grep -q "^error: failed to push some refs to '%(url)s'" - || { echo >&2 trap 1; exit 1; }
    echo "$t" | grep -F '[remote rejected]' - | grep -q -v -e ' xyz/[^ ]* (cannot delete references)' - && { echo >&2 trap 2; exit 1; }
    ;;
esac
set +x
xit=0
t=$( set -x ; git push --prune "%(url)s" "+refs/tags/*:refs/tags/*" 2>&1 ) || xit=$?
echo >&2 "$t"
date >&2 "+%%Y-%%m-%%d %%H:%%M:%%S"
case $xit in
( 0 )
    ;;
( * )
    echo "$t" | grep -q "^error: failed to push some refs to '%(url)s'" - || { echo >&2 trap 3; exit 1; }
    echo "$t" | grep -F '[remote rejected]' - | grep -q -v -e ' xyz/[^ ]* (cannot delete references)' - && { echo >&2 trap 4; exit 1; }
    ;;
esac
''' % {'url':xyzcity_url,} + postscript % {'fetchpush':'push', 'git':git,}, ] )

    if retcode:
        sys.stderr.write( '%s push(%s): error=%d\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git,retcode) )
    else:
        sys.stderr.write( '%s push(%s): OK\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git) )
    sys.stderr.flush()

    if processors:
        try:
            processors.get_nowait()
        except:
            pass

    return retcode

def runfetch( git, processors, que=None ):

# run a git fetch whenever a True arrives in que

    if que:
        while que.get():
            if fetchpush( git, processors ):
                os.kill( os.getpid(), signal.SIGINT )
    else:
        return fetchpush( git, processors )

    return

if __name__ == '__main__':

# separate the main program from the child threads

    pipe = None
    gits = []
    thrd = dict()
    qued = dict()

    def prefetch( git ):

    # ck for git mirror and log dir before running fetch

        gitpath = 'gits/%s.git' % (git)
        logpath = 'logs/%s.log' % (git)
        logdir = os.path.dirname( logpath )

        if not os.access( gitpath, os.F_OK ):
            sys.stderr.write( '%s prefetch(%s): %s not found\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git,gitpath) )
            sys.stderr.flush()
            return 1

        try:
            os.makedirs( logdir )
        except:
            pass

        return 0

    def pipecleaner():

        signal.signal( signal.SIGINT, signal.SIG_IGN )
        signal.signal( signal.SIGHUP, signal.SIG_IGN )
        signal.signal( signal.SIGTERM, signal.SIG_IGN )

    # try to shut down threads

        for git in gits:
            que = qued[git]
            if que:
                try:
                    while True:
                        qued[git].get_nowait()
                except:
                    pass
                try:
                    qued[git].put_nowait( False )
                except:
                    pass

    # try to shut down gerrit stream-events pipe process

        if pipe and ( pipe.poll() is None ):
            sys.stderr.write( '%s now kill the pipe with pid=%d\n' % ( time.strftime('%Y-%m-%d %H:%M:%S'), pipe.pid ) )
            sys.stderr.flush()
            pipe.terminate()
        elif pipe:
            sys.stderr.write( '%s pipe ended with status=%d\n' % ( time.strftime('%Y-%m-%d %H:%M:%S'), pipe.returncode ) )
            sys.stderr.flush()

    def piperunner():

    # startup sequence includes a fetch of every git whether needed or not

        for git in gits:
            qued[git].put_nowait( True )

      # sys.stderr.write( '%s sleep start\n' % ( time.strftime('%Y-%m-%d %H:%M:%S') ) )
      # sys.stderr.flush()
      # time.sleep(60)
      # sys.stderr.write( '%s sleep end\n' % ( time.strftime('%Y-%m-%d %H:%M:%S') ) )
      # sys.stderr.flush()

    # sits on gerrit stream-events pipe and handles events

        while True:
            git = None

            line = pipe.stdout.readline()
            if not line:
                break

            try:
                data=json.loads(line)
                if data['type'] == 'ref-updated':
                    git = data[ 'refUpdate' ][ 'project' ]
              # elif data['type'] == 'patchset-created':
              #     git = data[ 'change' ][ 'project' ]
              # else:
              #     raise RuntimeError('unrecognized gerrit event type %s' % (data['type']) )

            except:
                sys.stderr.write( '%s unrecognized line: %s\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),line) )
                sys.stderr.flush()

            if git:
                sys.stderr.write( '%s type=%s project=%s\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),data['type'],git) )
                sys.stderr.flush()
            if git and ( git in gits):
                if not prefetch( git ):
                    try:
                        qued[git].put_nowait( True )
                    except Queue.Full:
                        pass

        sys.stderr.write( '%s read EOF\n' % ( time.strftime('%Y-%m-%d %H:%M:%S') ) )
        sys.stderr.flush()

    def handler( signum, frame ):

    # signal handler

        sys.stderr.write( '%s killed by signal %d\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),signum) )
        sys.stderr.flush()
        pipecleaner()
        sys.exit(2)

    # get cmdline arguments == list of gits to mirror

    for arg in sys.argv[1:]:
        git = re.sub( r'^gits/', '', arg )
        git = re.sub( r'\.git$', '', git )
        if git in gits:
            continue

        sys.stderr.write( '%s found git=%s\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git) )
        sys.stderr.flush()

        if prefetch( git ):
            sys.stderr.write( '%s error from prefetch(%s)\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),git) )
            sys.stderr.flush()
            sys.exit(2)

        gits.append( git )

    if len( gits ) <= 0:
        sys.stderr.write( '%s %s: no commandline arguments\n' % (time.strftime('%Y-%m-%d %H:%M:%S'),sys.argv[0]) )
        sys.stderr.flush()
        sys.exit(2)

        # spawn a thread for each git

    signal.signal( signal.SIGINT, handler )
    signal.signal( signal.SIGHUP, handler )
    signal.signal( signal.SIGTERM, handler )

    processors = Queue.Queue(5)

    for git in gits:
        que = Queue.Queue( 1 )
        qued[ git ] = que
        thr = threading.Thread( target=runfetch, args=(git,processors,que) )
        thrd[ git ] = thr.start()

    # start gerrit stream-events pipe

    sys.stderr.write( '%s now start the pipe\n' % (time.strftime('%Y-%m-%d %H:%M:%S')) )
    sys.stderr.flush()

    pipe = subprocess.Popen(
        [ 'ssh', '-l', 'xyzbuild', '-i', '.ssh/id_rsa', '-p', '29418', 'git.allseenalliance.org', 'gerrit', 'stream-events', ],
        stdout=subprocess.PIPE,
    )
    # pipe = subprocess.Popen(['ssh', 'localhost', 'cat', 'testpipe'], stdout=subprocess.PIPE, )

    # start handling events

    try:
        piperunner()

    except:
        pipecleaner()
        raise

    pipecleaner()