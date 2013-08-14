# Author: Tomasz Wysocki <tomasz@wysocki.info>
function workonbranch {
    if [ "$1" = "" ]
    then
        echo "Usage: workonbranch [branch name]"
        return 1
    fi
    if [ "$CURRENT_BRANCH" != "" ]
    then
        deactivatebranch
    fi
    _WORKONBRANCH_OLD_PS1="$PS1"
    CURRENT_BRANCH="$1"
    PS1="[$CURRENT_BRANCH]$PS1"
}

function deactivatebranch {
    _branch_check_if_active || return 1

    PS1="$_WORKONBRANCH_OLD_PS1"
    unset CURRENT_BRANCH
}

function _branch_check_if_active {
    if [ "$CURRENT_BRANCH" = "" ]
    then
        echo "No branch activated"
        return 1
    fi
    return 0
}

function branch_push_for {
    OPTIND=0
    RECIVE_PACK='git receive-pack'
    while getopts "r:" O; do
        case "$O" in
          r)
            RECIVE_PACK="$RECIVE_PACK --reviewer $OPTARG"
            ;;
          c)
            RECIVE_PACK="$RECIVE_PACK --cc $OPTARG"
            ;;
        esac
    done;
    shift $((OPTIND-1));
    _branch_check_if_active || return 1
    git push --receive-pack="$RECIVE_PACK" origin "HEAD:refs/for/$CURRENT_BRANCH" $@
}

function branch_push_heads {
    _branch_check_if_active || return 1
    git push origin "HEAD:refs/heads/$CURRENT_BRANCH" $@
}

function branch_push_drafts {
    _branch_check_if_active || return 1
    git push origin "HEAD:refs/drafts/$CURRENT_BRANCH" $@
}

function branch_checkout {
    if [ "$1" != "" ]
    then
        workonbranch $1
    fi
    _branch_check_if_active || return 1
    git fetch -p && git checkout "origin/$CURRENT_BRANCH"
}

function close_branch {
    if [ "$1" = "" ]
    then
        echo "close_branch [branch name]"
        exit 1
    fi
    branch_checkout master && git merge origin/$1 --no-ff && branch_push_heads && git push origin :refs/heads/$1
}

_complete_branch() {
    # bash-completion for branch name
    # based on: http://devmanual.gentoo.org/tasks-reference/completion/index.html
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(git branch -r| grep origin | grep -v HEAD | sed 's/  origin\///')

    if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
_complete_user() {
    # bash-completion for git user
    # based on: http://devmanual.gentoo.org/tasks-reference/completion/index.html
    local cur prev opts
    COMPREPLY=()
    prev="${COMP_WORDS[$COMP_CWORD-1]}"
    cur="${COMP_WORDS[$COMP_CWORD]}"

    if [ "$prev" = "-r" -o "$prev" = "-c" ] ; then
        opts=$(git log --pretty=format:'%ae' | sort | uniq)
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
complete -F _complete_branch workonbranch
complete -F _complete_branch branch_checkout
complete -F _complete_branch close_branch
complete -F _complete_user branch_push_for
