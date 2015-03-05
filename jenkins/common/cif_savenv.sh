
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

echo >&2 + : BEGIN cif_savenv.sh

ci_declare_env() {
        # same as "declare -p -x" except suppress some variables
    local _xet="$-"
    set +x

    declare -px | awk '
    # continuation line - p means print
$1 " " $2 !~ /^declare -[^ ]+$/     { if( p+0 != 0 ) print; next; }
    # $0 contains "declare -x name=value"
                                    { p=0; v=$3 ""; sub( "=.*", "", v ); l=length( v ); u=toupper( v ); }
    # ignore variable if name less than 3 chars long
l+0 < 3                             { next; }
    # ignore variable if name does not start with letter
u "" ~ /^[^A-Z].*/                  { next; }
    # ignore the following variables, case-insensitive
u "" == "ALLUSERSPROFILE"           { next; }
u "" == "APPDATA"                   { next; }
u "" == "AUTO_RESUME"               { next; }
u "" == "BASH"                      { next; }
u "" == "BASHOPTS"                  { next; }
u "" == "BASHPID"                   { next; }
u "" == "BASH_ALIASES"              { next; }
u "" == "BASH_ARGC"                 { next; }
u "" == "BASH_ARGV"                 { next; }
u "" == "BASH_CMDS"                 { next; }
u "" == "BASH_COMMAND"              { next; }
u "" == "BASH_COMPAT"               { next; }
u "" == "BASH_ENV"                  { next; }
u "" == "BASH_EXECUTION_STRING"     { next; }
u "" == "BASH_LINENO"               { next; }
u "" == "BASH_REMATCH"              { next; }
u "" == "BASH_SOURCE"               { next; }
u "" == "BASH_SUBSHELL"             { next; }
u "" == "BASH_VERSINFO"             { next; }
u "" == "BASH_VERSION"              { next; }
u "" == "BASH_XTRACEFD"             { next; }
u "" == "CDPATH"                    { next; }
u "" == "CHILD_MAX"                 { next; }
u "" == "CLIENTNAME"                { next; }
u "" == "COLUMNS"                   { next; }
u "" == "COMMONPROGRAMFILES"        { next; }
u "" == "COMMONPROGRAMFILES(X86)"   { next; }
u "" == "COMMONPROGRAMW6432"        { next; }
u "" == "COMPREPLY"                 { next; }
u "" == "COMPUTERNAME"              { next; }
u "" == "COMP_CWORD"                { next; }
u "" == "COMP_KEY"                  { next; }
u "" == "COMP_LINE"                 { next; }
u "" == "COMP_POINT"                { next; }
u "" == "COMP_TYPE"                 { next; }
u "" == "COMP_WORDBREAKS"           { next; }
u "" == "COMP_WORDS"                { next; }
u "" == "COMSPEC"                   { next; }
u "" == "COPROC"                    { next; }
u "" == "DEFLOGDIR"                 { next; }
u "" == "DIRSTACK"                  { next; }
u "" == "DISPLAY"                   { next; }
u "" == "EMACS"                     { next; }
u "" == "ENV"                       { next; }
u "" == "EUID"                      { next; }
u "" == "EXECIGNORE"                { next; }
u "" == "FCEDIT"                    { next; }
u "" == "FIGNORE"                   { next; }
u "" == "FP_NO_HOST_CHECK"          { next; }
u "" == "FUNCNAME"                  { next; }
u "" == "FUNCNEST"                  { next; }
u "" == "GLOBIGNORE"                { next; }
u "" == "GNUPGHOME"                 { next; }
u "" == "GROUPS"                    { next; }
u "" == "HISTCHARS"                 { next; }
u "" == "HISTCMD"                   { next; }
u "" == "HISTCONTROL"               { next; }
u "" == "HISTFILE"                  { next; }
u "" == "HISTFILESIZE"              { next; }
u "" == "HISTIGNORE"                { next; }
u "" == "HISTSIZE"                  { next; }
u "" == "HISTTIMEFORMAT"            { next; }
#### == "HOME"                      { next; }
#### == "HOMEDRIVE"                 { next; }
#### == "HOMEPATH"                  { next; }
u "" == "HOSTFILE"                  { next; }
u "" == "HOSTNAME"                  { next; }
u "" == "HOSTTYPE"                  { next; }
u "" == "IFS"                       { next; }
u "" == "IGNOREEOF"                 { next; }
u "" == "INFOPATH"                  { next; }
u "" == "INPUTRC"                   { next; }
u "" == "LANG"                      { next; }
u "" == "LANGUAGE"                  { next; }
u "" == "LC_ALL"                    { next; }
u "" == "LC_COLLATE"                { next; }
u "" == "LC_CTYPE"                  { next; }
u "" == "LC_MESSAGES"               { next; }
u "" == "LC_NUMERIC"                { next; }
u "" == "LESS"                      { next; }
u "" == "LESSCHARSET"               { next; }
u "" == "LINENO"                    { next; }
u "" == "LINES"                     { next; }
#### == "LOCALAPPDATA"              { next; }
u "" == "LOGNAME"                   { next; }
u "" == "LOGONSERVER"               { next; }
u "" == "MACHTYPE"                  { next; }
u "" == "MAIL"                      { next; }
u "" == "MAILCHECK"                 { next; }
u "" == "MAILPATH"                  { next; }
u "" == "MAPFILE"                   { next; }
u "" == "MSYSTEM"                   { next; }
#### == "NUMBER_OF_PROCESSORS"      { next; }
u "" == "NLSPATH"                   { next; }
u "" == "OLDPWD"                    { next; }
u "" == "OPTARG"                    { next; }
u "" == "OPTERR"                    { next; }
u "" == "OPTIND"                    { next; }
u "" == "OS"                        { next; }
u "" == "OSTYPE"                    { next; }
#### == "PATH"                      { next; }
#### == "PATHEXT"                   { next; }
u "" == "PIPESTATUS"                { next; }
u "" == "PLINK_PROTOCOL"            { next; }
u "" == "POSIXLY_CORRECT"           { next; }
u "" == "PPID"                      { next; }
u "" == "PRINTER"                   { next; }
u "" == "PROCESSOR_ARCHITECTURE"    { next; }
u "" == "PROCESSOR_ARCHITEW6432"    { next; }
u "" == "PROCESSOR_IDENTIFIER"      { next; }
u "" == "PROCESSOR_LEVEL"           { next; }
u "" == "PROCESSOR_REVISION"        { next; }
u "" == "PROFILEREAD"               { next; }
u "" == "PROGRAMDATA"               { next; }
u "" == "PROGRAMFILES"              { next; }
u "" == "PROGRAMFILES(X86)"         { next; }
u "" == "PROGRAMW6432"              { next; }
u "" == "PROMPT_COMMAND"            { next; }
u "" == "PROMPT_DIRTRIM"            { next; }
u "" == "PS1"                       { next; }
u "" == "PS2"                       { next; }
u "" == "PS3"                       { next; }
u "" == "PS4"                       { next; }
u "" == "PSMODULEPATH"              { next; }
u "" == "PUBLIC"                    { next; }
u "" == "PWD"                       { next; }
u "" == "RANDOM"                    { next; }
u "" == "READLINE_LINE"             { next; }
u "" == "READLINE_POINT"            { next; }
u "" == "REPLY"                     { next; }
u "" == "SECONDS"                   { next; }
u "" == "SESSIONNAME"               { next; }
u "" == "SHELL"                     { next; }
u "" == "SHELLOPTS"                 { next; }
u "" == "SHLVL"                     { next; }
u "" == "SSH_AUTH_SOCK"             { next; }
u "" == "SSH_CLIENT"                { next; }
u "" == "SSH_CONNECTION"            { next; }
u "" == "SSH_TTY"                   { next; }
u "" == "SYSTEMDRIVE"               { next; }
u "" == "SYSTEMROOT"                { next; }
#### == "TEMP"                      { next; }
u "" == "TERM"                      { next; }
u "" == "TIMEFORMAT"                { next; }
u "" == "TMOUT"                     { next; }
#### == "TMP"                       { next; }
#### == "TMPDIR"                    { next; }
u "" == "TZ"                        { next; }
u "" == "UATDATA"                   { next; }
u "" == "UID"                       { next; }
u "" == "USER"                      { next; }
u "" == "USERDNSDOMAIN"             { next; }
u "" == "USERDOMAIN"                { next; }
u "" == "USERDOMAIN_ROAMINGPROFILE" { next; }
u "" == "USERNAME"                  { next; }
#### == "USERPROFILE"               { next; }
u "" == "VSEDEFLOGDIR"              { next; }
u "" == "WINDIR"                    { next; }
u "" == "XDG_RUNTIME_DIR"           { next; }
u "" == "XDG_SESSION_ID"            { next; }
u "" == "XFILESEARCHPATH"           { next; }
    # print this variable
                                    { p=1; print; }
'
    case "$_xet" in ( *x* ) set -x ;; esac
}
# export -f ci_declare_env   # not yet

ci_savenv() {
    case "${CI_ENV}" in ( /*env ) ;; ( * ) return ;; esac

    # writes exported variables and functions to file
    local _xet="$-"
    set +x

    mkdir -p "${CI_ENV}" 2>/dev/null || : ok

    local i j t
    for i in 0 1 2 3 4 5 6 7 8 9
    do
        for j in 0 1 2 3 4 5 6 7 8 9
        do
            t=$i$j
            case $t in ( 00 ) continue ;; esac
            test -f "${CI_ENV}/setenv$t.sh" && continue || break
        done
        test -f "${CI_ENV}/setenv$t.sh" && continue || break
    done

    ci_declare_env > "${CI_ENV}/setenv$t.sh"
    declare -pxf   > "${CI_ENV}/setfun$t.sh"

    cp -f "${CI_ENV}/setenv$t.sh" "${CI_ENV}/setenv.sh"
    cp -f "${CI_ENV}/setfun$t.sh" "${CI_ENV}/setfun.sh"

    case "${CI_VERBOSE}" in
    ( [NnFf]* )
        rm -f "${CI_ENV}/setenv$t.sh" "${CI_ENV}/setfun$t.sh"
        ;;
    esac

    case "$_xet" in ( *x* ) set -x ;; esac
}
# export -f ci_savenv   # not yet

echo >&2 + : END cif_savenv.sh
