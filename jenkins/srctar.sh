#!/bin/bash

# Copyright (c) 2014, AllSeen Alliance. All rights reserved.
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
#

set -e

function mkTheTable() {

    cat <<\theTable > $theTable

# This table defines how to make any kind of srctar we support.
# Not every srctar in this table is created every time.
# The script scans the table, selects the rows for the srctar type it wants, and ignores everything else.

# Each row of the table contains:

#   type  git c1  c2  top subs

# where:

#   type  = name + version of srctar file : ajtcl-0.0.1, for example
#   git   = git project : core/ajtcl, for example
#   c1    = first checkout (branch, tag, or rev) to try : RB14.06, for example
#   c2    = second checkout to try, if checkout c1 fails : master, for example
#         = "-" to just fail if checkout c1 fails
#   top   = starting from root of git workspace, cd "top" before continuing
#           embedded "=" is replaced by the string from column two
#   subs  = starting from "top" (see above), copy "subs"
#           (think: cd "$top" ; find $subs)
#         = "." means everything except .git .repo
#           embedded "=" is replaced by the string from column two

# NOTE: top and sub cannot both be "."

# type                      git                             c1          c2  top subs
# ========================  ==============================  ==========  ==  ==  =================================

        # combo srctar : master includes everything, but release only includes what is released

# final release by tag

alljoyn-suite-14.06.00_beta core/ajtcl                  v14.06.00_beta  -   .   =
alljoyn-suite-14.06.00_beta core/alljoyn                v14.06.00_beta  -   .   =
alljoyn-suite-14.06.00_beta services/base               v14.06.00_beta  -   .   =
alljoyn-suite-14.06.00_beta services/base_tcl           v14.06.00_beta  -   .   =

# release branch

alljoyn-suite-0.0.1406      core/ajtcl                      RB14.06     -   .   =
alljoyn-suite-0.0.1406      core/alljoyn                    RB14.06     -   .   =
alljoyn-suite-0.0.1406      services/base                   RB14.06     -   .   =
alljoyn-suite-0.0.1406      services/base_tcl               RB14.06     -   .   =

# master

alljoyn-suite-0.0.1         core/ajtcl                      master      -   .   =
alljoyn-suite-0.0.1         core/alljoyn                    master      -   .   =
alljoyn-suite-0.0.1         services/base                   master      -   .   =
alljoyn-suite-0.0.1         services/base_tcl               master      -   .   =
alljoyn-suite-0.0.1         devtools/codegen                master      +   .   =
alljoyn-suite-0.0.1         data/datadriven_api             master      +   .   =
alljoyn-suite-0.0.1         services/notification_viewer    master      +   .   =
alljoyn-suite-0.0.1         lighting/service_framework      master      +   .   =
alljoyn-suite-0.0.1         compliance/tests                master      +   .   =

        # ajtcl, alljoyn, lsf srctars : master only for lsf, it is not in the release

# final release by tag

alljoyn-14.06.00_beta           core/alljoyn            v14.06.00_beta  -   =   .
ajtcl-14.06.00_beta             core/ajtcl              v14.06.00_beta  -   =   .
ajtcl-services-14.06.00_beta    services/base_tcl       v14.06.00_beta  -   =   .

# release branch

alljoyn-0.0.1406            core/alljoyn                    RB14.06     -   =   .
ajtcl-0.0.1406              core/ajtcl                      RB14.06     -   =   .
ajtcl-services-0.0.1406     services/base_tcl               RB14.06     -   =   .

# master

alljoyn-0.0.1               core/alljoyn                    master      -   =   .
ajtcl-0.0.1                 core/ajtcl                      master      -   =   .
ajtcl-services-0.0.1        services/base_tcl               master      -   =   .
alljoyn-lsf-0.0.1           lighting/service_framework      master      -   =   .

        # "services" srctars

# final release by tag

    # first alljoyn/build_core
alljoyn-config-14.06.00_beta            core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-controlpanel-14.06.00_beta      core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-notification-14.06.00_beta      core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-onboarding-14.06.00_beta        core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-sample_apps-14.06.00_beta       core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-services_common-14.06.00_beta   core/alljoyn    v14.06.00_beta  -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
alljoyn-config-14.06.00_beta            services/base   v14.06.00_beta  -   .   =/config            =/sample_apps
alljoyn-controlpanel-14.06.00_beta      services/base   v14.06.00_beta  -   .   =/controlpanel      =/sample_apps
alljoyn-notification-14.06.00_beta      services/base   v14.06.00_beta  -   .   =/notification      =/sample_apps
alljoyn-onboarding-14.06.00_beta        services/base   v14.06.00_beta  -   .   =/onboarding        =/sample_apps
alljoyn-sample_apps-14.06.00_beta       services/base   v14.06.00_beta  -   .                       =/sample_apps
alljoyn-services_common-14.06.00_beta   services/base   v14.06.00_beta  -   .   =/services_common   =/sample_apps

# release branch version

    # first alljoyn/build_core
alljoyn-config-0.0.1406             core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-controlpanel-0.0.1406       core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-notification-0.0.1406       core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-onboarding-0.0.1406         core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-sample_apps-0.0.1406        core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-services_common-0.0.1406    core/alljoyn            RB14.06     -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
alljoyn-config-0.0.1406             services/base           RB14.06     -   .   =/config            =/sample_apps
alljoyn-controlpanel-0.0.1406       services/base           RB14.06     -   .   =/controlpanel      =/sample_apps
alljoyn-notification-0.0.1406       services/base           RB14.06     -   .   =/notification      =/sample_apps
alljoyn-onboarding-0.0.1406         services/base           RB14.06     -   .   =/onboarding        =/sample_apps
alljoyn-sample_apps-0.0.1406        services/base           RB14.06     -   .                       =/sample_apps
alljoyn-services_common-0.0.1406    services/base           RB14.06     -   .   =/services_common   =/sample_apps

# master branch version

    # first alljoyn/build_core
alljoyn-config-0.0.1                core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-controlpanel-0.0.1          core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-notification-0.0.1          core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-onboarding-0.0.1            core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-sample_apps-0.0.1           core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
alljoyn-services_common-0.0.1       core/alljoyn            master      -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
alljoyn-config-0.0.1                services/base           master      -   .   =/config            =/sample_apps
alljoyn-controlpanel-0.0.1          services/base           master      -   .   =/controlpanel      =/sample_apps
alljoyn-notification-0.0.1          services/base           master      -   .   =/notification      =/sample_apps
alljoyn-onboarding-0.0.1            services/base           master      -   .   =/onboarding        =/sample_apps
alljoyn-sample_apps-0.0.1           services/base           master      -   .                       =/sample_apps
alljoyn-services_common-0.0.1       services/base           master      -   .   =/services_common   =/sample_apps
theTable
}

function mkBuildInfo() {

    cat <<\buildInfo > $buildInfo.py
import re
import sys
from subprocess import *

def GetBuildInfo(env, source, stderr=PIPE ):
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
    for b in branches:
        if b[0] == '*':
            branch = b[2:]
            break

    tag = None
    commit_delta = None
    commit_hash = None
    gitname = 'Git'

    if remotes:
        for l in remotes:
            m = re.search( r'^origin\s(?P<url>.*)\s\(fetch\)$', l )
            if m:
                n = re.search( r'^.*/(?P<gitname>.+)$', m.group('url').strip() )
                if n:
                    gitname = 'Git: %s' % ( n.group('gitname').strip() )
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
    source = ''
    if argv and argv[0]:
        source = argv[0].strip()
    if source == '':
        source = '.'

    bld_string = GetBuildInfo( env, source, stderr=None )

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
buildInfo
}

function doWork() {

    local srctar srctarDir
    case "$-" in ( *x* ) debug=-x ;; ( * ) debug=+x ;; esac

    while test -n "$1"
    do
        srctar="$1"
        shift

        echo >&2
        echo >&2 "srctar: $srctar"
        echo >&2

        srctarDir="$PWD/depot/$srctar-src"
        ls -d "$srctarDir" 2>/dev/null && exit 6
        mkdir  "$srctarDir"

        set +x
        while read type git c1 c2 top subs
        do
            case "$debug" in ( -* ) echo >&2 "table: $type $git $c1 $c2 $top $subs" ;; esac
            # get next line from table
            case "$type" in ( "" | \#* ) continue ;;    ( *[\"\'\#]* )  exit 3 ;; ( "$srctar" ) ;; ( * ) continue ;; esac
            case "$git"  in ( "" ) continue ;;  ( *[\"\'\#\|]* )    exit 3 ;; esac
            case "$c1"   in ( "" ) continue ;;  ( *[\'\"\#]* )      exit 3 ;; esac
            case "$c2"   in ( "" ) continue ;;  ( *[\'\"\#]* )      exit 3 ;; esac
            case "$top"  in ( "" ) continue ;;  ( *[\'\"\#\|]* | /* | *\** )   exit 3 ;; esac
            case "$subs" in ( "" ) continue ;;  ( *[\'\"\#\|]* )    exit 3 ;; esac
            for s in $subs
            do
                case "$s" in ( /* ) exit 4 ;; esac
                case "$top" in ( . ) case "$s" in ( .* | *\** ) exit 5 ;; esac ;; esac
            done

            case "$debug" in ( +* ) echo >&2 "table: $type $git $c1 $c2 $top $subs" ;; esac
            set $debug
            prev=${gitRevA["$git"]}
            next="$c1|$c2"
            case "$next" in
            ( "$prev" )
                # same checkouts as last time through this git - nothing to do
                case "${tellA[$git]}" in ( true ) echo >&3 true ;; esac
                ;;
            ( * )
                # clone new local workspace
                rm -rf "gits/$git"
                git clone "$url/$git" "gits/$git"

                # checkout c1 and/or c2
                (
                    cd "gits/$git"
                    git checkout "$c1" && { echo >&3 "tellA[$git]=true" ; exit 0 ; }
                    case "$c2" in ( - ) exit 2 ;; ( + ) exit 0 ;; esac
                    git checkout "$c2" && exit 0
                    exit 2
                )
                gitRevA["$git"]="$next"
                buildInfoA["$git"]=$( python $buildInfo.py "gits/$git" )
                ;;
            esac

            # re-write equals signs
            top=$(  echo "$top"  | sed -e "s|=|$git|g" )
            subs=$( echo "$subs" | sed -e "s|=|$git|g" )

            # cd to top, copy subs to srctar
            (
                cd "gits/$top"
                find $subs -depth \( -type d -name .git -prune \) -o \( -type f ! -name .gitignore -print \) | cpio -pmdl "$srctarDir"
            )
            echo "${buildInfoA["$git"]}" >> "$srctarDir/manifest.txt"
            set +x
        done < $theTable 3>$tell
        set $debug
        case "$(<$tell)" in ( "" ) exit 4 ;; esac
        source $tell
        ( cd depot && tar -czf "$srctar-src.tar.gz" "$srctar-src" && rm -rf "$srctar-src" )
    done
}

# script starts here

tell=/tmp/$$.tell
theTable=/tmp/$$.theTable
buildInfo=/tmp/$$.buildInfo

rm          -rf $tell $theTable $buildInfo.py $buildInfo.pyc
trap    "rm -rf $tell $theTable $buildInfo.py $buildInfo.pyc" 0 1 2 3 15

mkTheTable
mkBuildInfo

rm -rf gits depot
mkdir gits depot

declare -A gitRevA buildInfoA tellA

url=https://git.allseenalliance.org/gerrit

doWork alljoyn-suite-0.0.1406
doWork alljoyn-0.0.1406
doWork ajtcl-0.0.1406
doWork ajtcl-services-0.0.1406
doWork alljoyn-config-0.0.1406
doWork alljoyn-controlpanel-0.0.1406
doWork alljoyn-notification-0.0.1406
doWork alljoyn-onboarding-0.0.1406
doWork alljoyn-sample_apps-0.0.1406
doWork alljoyn-services_common-0.0.1406

# activate this block when release tag v14.06.00_beta is set, run the jenkins build manually, then comment out again

# doWork alljoyn-suite-14.06.00_beta
# doWork alljoyn-14.06.00_beta
# doWork ajtcl-14.06.00_beta
# doWork ajtcl-services-14.06.00_beta
# doWork alljoyn-config-14.06.00_beta
# doWork alljoyn-controlpanel-14.06.00_beta
# doWork alljoyn-notification-14.06.00_beta
# doWork alljoyn-onboarding-14.06.00_beta
# doWork alljoyn-sample_apps-14.06.00_beta

