
Two types of Git mirrors are supported

1. pullpush : pulls from AllSeen into subtree ./gits, then pushes to another (remote) Git mirror:
    XyzCity Gerrit server, for example

2. pullhere : pulls from AllSeen into subtree ./gits, which can itself be a Git mirror handled by
    git-daemon, for example;
    then automatically updates the corresponding Git workspaces under subtree ./branches, if found.

Both types of Git mirrors consist of a root directory location (corresponding to this README file), under
which are located subtrees as follow:

    ./bin   # scripts
    ./gits  # local Git projects including "path" structure. Created when a Git project is initialized.
    ./logs  # log files corresponding to each Git project. Files/directories created automatically.
    ./.ssh  # private SSH keys used in Gerrit stream-events command
    ./branches  # (pullhere type only, may be omitted entirely or in part)
            # Git workspaces for each Git project/branch desired
            # Created when a Git project is initialized.

The following remote Git urls are baked-into mirror.py and/or the local Git projects under .gits (config files):
Grep and edit to change.

    ssh://xyzbuild@git.allseenalliance.org:29418
    ssh://xyzbuild@git-xyzcity:29418/allseen

    These urls are also used in the examples showing how to initialize a new Git project (this file, below).

The following Gerrit commands w remote server addresses are baked-into mirror.py files.
Grep and edit to change.

    [ 'ssh', '-l', 'xyzbuild', '-i', '.ssh/id_rsa', '-p', '29418', 'git-xyzcity', 'gerrit', 'stream-events', ],
    [ 'ssh', '-l', 'xyzbuild', '-i', '.ssh/id_rsa', '-p', '29418', 'git.allseenalliance.org', 'gerrit', 'stream-events', ],

Note: for these Gerrit commands, the appropriate private SSH keys must be provided in subtree ./.ssh of the mirror.
However, the Git commands run by mirror.py use whatever private keys ssh can find in the environment; typically $HOME/.ssh

To add a new Git project to a mirror:

    Each new Git project MUST be initialized in advance, in subtrees ./gits (and ./branches if applicable).
    Then, restart the mirror.
    Examples:

    1. Add a new Git project to a pullpush mirror

    url=ssh://xyzbuild@git.allseenalliance.org:29418
    h=$PWD
    for p in extras/automation  # Git projects
    do
        rm -rf gits/$p.git
        git clone --mirror --bare $url/$p.git gits/$p.git
        read okay
    done

    2. Add a new Git project to a pullhere mirror

    url=ssh://xyzbuild@git-xyzcity:29418/allseen
    h=$PWD
    for p in allseen/extras/automation  # Git projects
    do
        rm -rf gits/$p.git
        git clone --mirror --bare $url/$p.git gits/$p.git
        for b in xyz/sea/master     # any Git branches that you want to maintain local workspaces for- optional
        do
            rm -rf branches/$p/$b
            git init branches/$p/$b
            ( cd branches/$p/$b && git remote add -t $b origin $h/gits/$p.git && git fetch origin && git checkout -b $b origin/$b && git log -1 )
            read okay
        done
    done

# crontab to run pullpush Git mirror

SHELL=/bin/bash
PULLPUSH_GITCACHE=/local/srv/allseen-mirror
## m h  dom mon dow   command
*/5   *  *   *   *   cd $PULLPUSH_GITCACHE || exit 2 && fuser -s logs/mirror.log > /dev/null 2>&1 && exit 0 || bash bin/mirror.sh
 4    *  *   *   *   cd $PULLPUSH_GITCACHE || exit 2 && pkill -u $LOGNAME -f  -- '^python bin/mirror\.py gits/'
 4   23  *   *   *   cd $PULLPUSH_GITCACHE || exit 2 && rm -f logs/mirror.start
@reboot              cd $PULLPUSH_GITCACHE || exit 2 && rm -f logs/mirror.start

# crontab to run pullhere Git mirror

SHELL=/bin/bash
PULLHERE_GITCACHE=/local/srv/xyzcity-mirror
## m h  dom mon dow   command
*/5   *  *   *   *   cd $PULLHERE_GITCACHE || exit 2 && fuser -s logs/mirror.log > /dev/null 2>&1 && exit 0 || bash bin/mirror.sh
 4   23  *   *   *   cd $PULLHERE_GITCACHE || exit 2 && rm -f logs/mirror.start
@reboot              cd $PULLHERE_GITCACHE || exit 2 && rm -f logs/mirror.start

