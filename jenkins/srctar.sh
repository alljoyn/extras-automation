#!/bin/bash

# Copyright (c) 2014 - 2015, AllSeen Alliance. All rights reserved.
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

    case "$1" in ( "" | *\ * ) fxit 1 "mkTheTable, bad argv1='$1'" ;; esac
    argv1="$1"
    shift

    awk <<theTable > $theTable "\$1 \"\" == \"$argv1\"   { t = \"\" ; for( i=2; i<=NF; i++ ) { t = t \" \" \$i ; } ; print t ; next ; }"

# This table defines how to make any kind of srctar we support.
# Not every srctar in this table is created every time.

# Two passes on this table need to happen in order to write a srctar.

# First, the text embedded below is written out to a tmp file, by calling function mkTheTable, with arguments.
# The first argument selects which rows will be written out, by matching the first token on each line seen below.
# That first token is removed when the line is written out to the tmp file.
# The second, third, etc arguments are simply expanded wherever they occur in the text as it is written to the tmp file.
# Note that the first argument to mkTheTable is immediately shifted away, so $1 in the table text actually expands the second argument,
# $2 expands the third argument, etc.
# You could build any kind of scheme depending how you coded the table and called the function, but the scheme right now is as follows:
#   first  arg == the first token in all active lines in this table is either "coreMaster" or "coreR14.06"
#   second arg == $1 : file version embedded in "name" field : the "0.0.1" in filename "alljoyn-0.0.1-src", for example
#   third  arg == $2 : coded in "c1" field : as described below: "master", for example

# Second, the tmp file is read by the doWork function, which actually generates srctar files: one srctar file per argument.
# Each argument names the srctar file to be generated AND selects rows from the tmp file, describing what source goes in it.
# Rows from the tmp file are as follows
#   name  git c1  c2  top subs
# where:
#   name  = complete filename of the srctar : ajtcl-0.0.1-src, for example
#   git   = git project : core/ajtcl, for example
#   c1    = first checkout (branch, tag, or rev) to try : RB14.06, for example
#   c2    = second checkout to try, if checkout c1 fails : master, for example
#         = "-" to just fail if checkout c1 fails
#   top   = starting from root of git workspace, cd "top" before continuing
#           embedded "=" is replaced by the string from column two
#   subs  = starting from "top" (see above), copy "subs"
#           (think: cd "\$top" ; find \$subs)
#         = "." means everything except .git .repo
#           embedded "=" is replaced by the string from column two

# NOTE: top and sub cannot both be "."

#               name                            git                             c1          c2  top subs
#               ========================        ==============================  ==========  ==  ==  =================================

        # combo srctar : master includes everything, but release only includes what is released

# release (14.06)

coreR14.06      alljoyn-suite-${1}-src          compliance/tests                ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          core/ajtcl                      ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          core/alljoyn                    ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          devtools/codegen                ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          lighting/service_framework      ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          services/base                   ${2}        -   .   =
coreR14.06      alljoyn-suite-${1}-src          services/base_tcl               ${2}        -   .   =

# master

coreMaster      alljoyn-suite-${1}-src          compliance/tests                ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          core/ajtcl                      ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          core/alljoyn                    ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          core/alljoyn-js                 ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          data/datadriven_api             ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          devtools/codegen                ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          lighting/service_framework      ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          services/base                   ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          services/base_tcl               ${2}        -   .   =
coreMaster      alljoyn-suite-${1}-src          services/notification_viewer    ${2}        -   .   =

# release (14.12) in progress, 2014-11-24

coreR14.12      alljoyn-suite-${1}-src          core/ajtcl                      ${2}        -   .   =
coreR14.12      alljoyn-suite-${1}-src          core/alljoyn                    ${2}        -   .   =

        # ajtcl, alljoyn, lsf srctars

# release (14.06)

coreR14.06      ajtcl-${1}-src                  core/ajtcl                      ${2}        -   =   .
coreR14.06      ajtcl-services-${1}-src         services/base_tcl               ${2}        -   =   .
coreR14.06      alljoyn-${1}-src                core/alljoyn                    ${2}        -   =   .
coreR14.06      alljoyn-lsf-${1}-src            lighting/service_framework      ${2}        -   =   .

# master

coreMaster      ajtcl-${1}-src                  core/ajtcl                      ${2}        -   =   .
coreMaster      ajtcl-services-${1}-src         services/base_tcl               ${2}        -   =   .
coreMaster      alljoyn-${1}-src                core/alljoyn                    ${2}        -   =   .
coreMaster      alljoyn-js-${1}-src             core/alljoyn-js                 ${2}        -   =   .
coreMaster      alljoyn-lsf-${1}-src            lighting/service_framework      ${2}        -   =   .

# release (14.12)

coreR14.12      ajtcl-${1}-src                  core/ajtcl                      ${2}        -   =   .
coreR14.12      ajtcl-services-${1}-src         services/base_tcl               ${2}        -   =   .
coreR14.12      alljoyn-${1}-src                core/alljoyn                    ${2}        -   =   .
coreR14.12      alljoyn-js-${1}-src             core/alljoyn-js                 ${2}        -   =   .
coreR14.12      alljoyn-lsf-${1}-src            lighting/service_framework      ${2}        -   =   .

        # "services" srctars

# release (14.06)

    # first alljoyn/build_core
coreR14.06      alljoyn-config-${1}-src                 core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.06      alljoyn-controlpanel-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.06      alljoyn-notification-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.06      alljoyn-onboarding-${1}-src             core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.06      alljoyn-sample_apps-${1}-src            core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.06      alljoyn-services_common-${1}-src        core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
coreR14.06      alljoyn-config-${1}-src                 services/base           ${2}        -   .   =/config            =/sample_apps
coreR14.06      alljoyn-controlpanel-${1}-src           services/base           ${2}        -   .   =/controlpanel      =/sample_apps
coreR14.06      alljoyn-notification-${1}-src           services/base           ${2}        -   .   =/notification      =/sample_apps
coreR14.06      alljoyn-onboarding-${1}-src             services/base           ${2}        -   .   =/onboarding        =/sample_apps
coreR14.06      alljoyn-sample_apps-${1}-src            services/base           ${2}        -   .                       =/sample_apps
coreR14.06      alljoyn-services_common-${1}-src        services/base           ${2}        -   .   =/services_common   =/sample_apps

# master

    # first alljoyn/build_core
coreMaster      alljoyn-config-${1}-src                 core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreMaster      alljoyn-controlpanel-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreMaster      alljoyn-notification-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreMaster      alljoyn-onboarding-${1}-src             core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreMaster      alljoyn-sample_apps-${1}-src            core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreMaster      alljoyn-services_common-${1}-src        core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
coreMaster      alljoyn-config-${1}-src                 services/base           ${2}        -   .   =/config            =/sample_apps
coreMaster      alljoyn-controlpanel-${1}-src           services/base           ${2}        -   .   =/controlpanel      =/sample_apps
coreMaster      alljoyn-notification-${1}-src           services/base           ${2}        -   .   =/notification      =/sample_apps
coreMaster      alljoyn-onboarding-${1}-src             services/base           ${2}        -   .   =/onboarding        =/sample_apps
coreMaster      alljoyn-sample_apps-${1}-src            services/base           ${2}        -   .                       =/sample_apps
coreMaster      alljoyn-services_common-${1}-src        services/base           ${2}        -   .   =/services_common   =/sample_apps

# release (14.12) in progress, 2014-11-24

    # first alljoyn/build_core
coreR14.12      alljoyn-config-${1}-src                 core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.12      alljoyn-controlpanel-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.12      alljoyn-notification-${1}-src           core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.12      alljoyn-onboarding-${1}-src             core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.12      alljoyn-sample_apps-${1}-src            core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
coreR14.12      alljoyn-services_common-${1}-src        core/alljoyn            ${2}        -   .   =/build_core    =/SConstruct    =/README.md
    # then the individual service subtree
coreR14.12      alljoyn-config-${1}-src                 services/base           ${2}   master   .   =/config            =/sample_apps
coreR14.12      alljoyn-controlpanel-${1}-src           services/base           ${2}   master   .   =/controlpanel      =/sample_apps
coreR14.12      alljoyn-notification-${1}-src           services/base           ${2}   master   .   =/notification      =/sample_apps
coreR14.12      alljoyn-onboarding-${1}-src             services/base           ${2}   master   .   =/onboarding        =/sample_apps
coreR14.12      alljoyn-sample_apps-${1}-src            services/base           ${2}   master   .                       =/sample_apps
coreR14.12      alljoyn-services_common-${1}-src        services/base           ${2}   master   .   =/services_common   =/sample_apps
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

        srctarDir="$PWD/depot/$srctar"
        ls -d "$srctarDir" 2>/dev/null && fxit 2 "doWork, directory should not exist: srctarDir='$srctarDir'"
        mkdir  "$srctarDir"

        set +x
        while read name git c1 c2 top subs
        do
            case "$debug" in ( -* ) echo >&2 "table: $name $git $c1 $c2 $top $subs" ;; esac
            # get next line from table
            case "$name" in ( "" | \#* ) continue ;;    ( *[\"\'\#]* )  fxit 1 "doWork, table, bad name='$name'" ;; ( "$srctar" ) ;; ( * ) continue ;; esac
            case "$git"  in ( "" ) continue ;;  ( *[\"\'\#\|]* )    fxit 1 "doWork, table, bad git='$git'" ;; esac
            case "$c1"   in ( "" ) continue ;;  ( *[\'\"\#]* )      fxit 1 "doWork, table, bad c1='$c1'" ;; esac
            case "$c2"   in ( "" ) continue ;;  ( *[\'\"\#]* )      fxit 1 "doWork, table, bad c2='$c2'" ;; esac
            case "$top"  in ( "" ) continue ;;  ( *[\'\"\#\|]* | /* | *\** )   fxit 1 "doWork, table, bad top='$top'" ;; esac
            case "$subs" in ( "" ) continue ;;  ( *[\'\"\#\|]* )    fxit 1 "doWork, table, bad subs='$subs'" ;; esac
            for s in $subs
            do
                case "$s" in ( /* ) fxit 1 "doWork, table, subs='$subs', bad s='$s', cannot start with /" ;; esac
                case "$top" in ( . ) case "$s" in ( .* | *\** ) fxit 1 "doWork, table, subs='$subs', bad s='$s', top and subs cannot both be ." ;; esac ;; esac
            done

            case "$debug" in ( +* ) echo >&2 "table: $name $git $c1 $c2 $top $subs" ;; esac
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
                    case "$c2" in ( - ) fxit 2 "doWork, checkout c1 failed : c1='$c1'" ;; ( + ) exit 0 ;; esac
                    git checkout "$c2" && exit 0
                    fxit 2 "doWork, checkout c2 failed : c2='$c2'"
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
                find $subs \( -type d -name .git -prune \) -o \( -type f ! -name .gitignore -print \) | cpio -pmdl "$srctarDir"
            )
            echo "${buildInfoA["$git"]}" >> "$srctarDir/manifest.txt"
            set +x
        done < $theTable 3>$tell
        set $debug
        case "$(<$tell)" in ( "" ) fxit 2 "doWork, no checkout c1 in this srctar was successful" ;; esac
        source $tell
        ( cd depot && tar -czf "$srctar.tar.gz" "$srctar" && rm -rf "$srctar" )
    done
}

function fxit {
    set +xe
    local xit="${1:-1}"
    shift
    case "$xit" in
    ( 0 )
        echo >&2 "$@"
        echo >&2 exit OK
    ;;
    ( * )
        echo >&2 error: "$@"
        echo >&2 exit "$xit"
    ;;
    esac
    set $debug
    exit "$xit"
}

# script starts here

tell=/tmp/$$.tell
theTable=/tmp/$$.theTable
buildInfo=/tmp/$$.buildInfo

rm          -rf $tell $theTable $buildInfo.py $buildInfo.pyc
trap    "rm -rf $tell $theTable $buildInfo.py $buildInfo.pyc" 0 1 2 3 15

mkBuildInfo

rm -rf gits depot
mkdir gits depot

declare -A gitRevA buildInfoA tellA

export url=https://git.allseenalliance.org/gerrit


fileVersion=0.0.1

mkTheTable  coreMaster  $fileVersion    master

# activate this block if jenkins triggers builds on master branch
# doWork ajtcl-$fileVersion-src
# doWork ajtcl-services-$fileVersion-src
# doWork alljoyn-$fileVersion-src
# doWork alljoyn-config-$fileVersion-src
# doWork alljoyn-controlpanel-$fileVersion-src
# doWork alljoyn-js-$fileVersion-src
# doWork alljoyn-lsf-$fileVersion-src
# doWork alljoyn-notification-$fileVersion-src
# doWork alljoyn-onboarding-$fileVersion-src
# doWork alljoyn-sample_apps-$fileVersion-src
# doWork alljoyn-services_common-$fileVersion-src
# doWork alljoyn-suite-$fileVersion-src


fileVersion=0.0.1406

mkTheTable  coreR14.06  $fileVersion    RB14.06

# activate this block if jenkins triggers builds on branch RB14.06
# doWork ajtcl-$fileVersion-src
# doWork ajtcl-services-$fileVersion-src
# doWork alljoyn-$fileVersion-src
# doWork alljoyn-config-$fileVersion-src
# doWork alljoyn-controlpanel-$fileVersion-src
# doWork alljoyn-lsf-$fileVersion-src
# doWork alljoyn-notification-$fileVersion-src
# doWork alljoyn-onboarding-$fileVersion-src
# doWork alljoyn-sample_apps-$fileVersion-src
# doWork alljoyn-services_common-$fileVersion-src
# doWork alljoyn-suite-$fileVersion-src


fileVersion=0.0.1412

mkTheTable  coreR14.12  $fileVersion    RB14.12

# activate this block if jenkins triggers builds on branch RB14.12
# doWork ajtcl-$fileVersion-src
# doWork ajtcl-services-$fileVersion-src
# doWork alljoyn-$fileVersion-src
# doWork alljoyn-config-$fileVersion-src
# doWork alljoyn-controlpanel-$fileVersion-src
# doWork alljoyn-notification-$fileVersion-src
# doWork alljoyn-lsf-$fileVersion-src
# doWork alljoyn-onboarding-$fileVersion-src
# doWork alljoyn-sample_apps-$fileVersion-src
# doWork alljoyn-services_common-$fileVersion-src
# doWork alljoyn-suite-$fileVersion-src
