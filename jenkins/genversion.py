
# Copyright (c) 2016 Open Connectivity Foundation (OCF) and AllJoyn Open
#    Source Project (AJOSP) Contributors and others.
#
#    SPDX-License-Identifier: Apache-2.0
#
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Copyright 2016 Open Connectivity Foundation and Contributors to
#    AllSeen Alliance. All rights reserved.
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

import re
import sys
from subprocess import *

def GetBuildInfo(env, source, stderr=PIPE, given_branch=None ):
    branches = []
    tags = []
    remotes = []
    if env.has_key('GIT'):
        try:
            remotes = Popen([env['GIT'], 'remote', '-v'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
            branches = Popen([env['GIT'], 'branch'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
            tags = Popen([env['GIT'], 'describe', '--always', '--long', '--abbrev=40'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
        except WindowsError as e:
            if e[0] == 2:
                try:
                    project = Popen([env['GIT'], 'remote', '-v'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
                    branches = Popen([env['GIT'] + '.cmd', 'branch'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
                    tags = Popen([env['GIT'] + '.cmd', 'describe', '--always', '--long', '--abbrev=40'], stdout = PIPE, stderr = stderr, cwd = source).communicate()[0].splitlines()
                except:
                    pass
        except:
            pass

    branch = None
    if given_branch:
        branch = '(given as ' + given_branch + ')'
    for b in branches:
        if b[0] == '*' and not re.search( r'detached from', b[2:] ) and not re.search( r'no branch', b[2:] ):
            branch = b[2:]
            break

    tag = None
    commit_delta = None
    commit_hash = None
    gitname = 'Git'

    if remotes:
        for l in remotes:
            m = re.search( r'^\S+\s(?P<url>.*)\s\(fetch\)$', l )
            if m:
                n = re.search( r'^.*/(?P<gitname>.+)$', m.group('url').strip() )
                if n:
                    p = re.sub( r'\.git$', '', n.group('gitname').strip(), flags=re.I )
                    gitname = 'Git: %s.git' % ( p )
                    break

    if tags:
        if tags[0].find('-') >= 0:
            tag, commit_delta, commit_hash = tuple(tags[0].rsplit('-',2))
            commit_hash = commit_hash[1:]  # lop off the "g"
        else:
            tag = '<none>'
            commit_delta = 0;
            commit_hash = tags[0]

    if branch or commit_hash:
        bld_string = gitname
    else:
        bld_string = ''
    if branch:
        bld_string += " branch: '%s'" % branch
    if commit_hash:
        bld_string += " tag: '%s'" % tag
        if commit_delta:
            bld_string += ' (+%s changes)' % commit_delta
        if commit_delta or tag == '<none>':
            bld_string += ' commit ref: %s' % commit_hash

    return bld_string

# "main" calls GetBuildInfo() and prints bld_string on stdout
# "main" takes one argument: path to git workspace (optional)
# "git" executable is expected to be found in PATH

def main( argv=None ):
    env = dict()
    env['GIT'] = 'git'
    source = '.'
    given_branch = None
    if argv and argv[0] and argv[0].strip() != '':
        source = argv[0].strip()
        if len(argv) > 1 and argv[1] and argv[1].strip() != '':
            given_branch = argv[1].strip()

    bld_string = GetBuildInfo( env, source, stderr=None, given_branch=given_branch )

    if bld_string and bld_string != '':
        print '%s' % ( bld_string )
        return 0
    else:
        sys.stderr.write( 'error, unable to get Git version info\n' )
        sys.stderr.flush()
        return 1

if __name__ == '__main__':
    if len(sys.argv) > 1:
        sys.exit(main(sys.argv[1:]))
    else:
        sys.exit(main())