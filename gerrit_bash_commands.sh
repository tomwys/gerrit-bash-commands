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
    _branch_check_if_active || return 1
    git push origin "HEAD:refs/for/$CURRENT_BRANCH"
}

function branch_push_heads {
    _branch_check_if_active || return 1
    git push origin "HEAD:refs/heads/$CURRENT_BRANCH"
}

function branch_checkout {
    _branch_check_if_active || return 1
    git fetch -p && git checkout "origin/$CURRENT_BRANCH"
}

_workonbranch() {
    # bash-completion for workonbranch
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
complete -F _workonbranch workonbranch
