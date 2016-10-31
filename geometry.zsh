# Geometry
# Based on Avit and Pure
# avit: https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/avit.zsh-theme
# pure: https://github.com/sindresorhus/pure

# Define how to colorize before the variables
prompt_geometry_colorize() {
    echo "%F{$1}$2%f"
}

# Color definitions
GEOMETRY_COLOR_GIT_DIRTY=${GEOMETRY_COLOR_GIT_DIRTY:-red}
GEOMETRY_COLOR_GIT_CLEAN=${GEOMETRY_COLOR_GIT_CLEAN:-green}
GEOMETRY_COLOR_GIT_CONFLICTS_UNSOLVED=${GEOMETRY_COLOR_GIT_CONFLICTS_UNSOLVED:-red}
GEOMETRY_COLOR_GIT_CONFLICTS_SOLVED=${GEOMETRY_COLOR_GIT_CONFLICTS_SOLVED:-green}
GEOMETRY_COLOR_GIT_BRANCH=${GEOMETRY_COLOR_GIT_BRANCH:-242}
GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_SHORT=${GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_SHORT:-green}
GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_NEUTRAL=${GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_NEUTRAL:-white}
GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_LONG=${GEOMETRY_COLOR_GIT_TIME_SINCE_COMMIT_LONG:-red}
GEOMETRY_COLOR_EXIT_VALUE=${GEOMETRY_COLOR_EXIT_VALUE:-magenta}
GEOMETRY_COLOR_VIRTUALENV=${GEOMETRY_COLOR_PROMPT:-green}
GEOMETRY_COLOR_PROMPT=${GEOMETRY_COLOR_PROMPT:-white}
GEOMETRY_COLOR_ROOT=${GEOMETRY_COLOR_ROOT:-red}
GEOMETRY_COLOR_DIR=${GEOMETRY_COLOR_DIR:-blue}

# Symbol definitions
GEOMETRY_SYMBOL_PROMPT=${GEOMETRY_SYMBOL_PROMPT:-"▲"}
GEOMETRY_SYMBOL_RPROMPT=${GEOMETRY_SYMBOL_RPROMPT:-"◇"}
GEOMETRY_SYMBOL_EXIT_VALUE=${GEOMETRY_SYMBOL_EXIT_VALUE:-"△"}
GEOMETRY_SYMBOL_ROOT=${GEOMETRY_SYMBOL_ROOT:-"▲"}
GEOMETRY_SYMBOL_GIT_DIRTY=${GEOMETRY_SYMBOL_GIT_DIRTY:-"⬡"}
GEOMETRY_SYMBOL_GIT_CLEAN=${GEOMETRY_SYMBOL_GIT_CLEAN:-"⬢"}
GEOMETRY_SYMBOL_GIT_REBASE=${GEOMETRY_SYMBOL_GIT_REBASE:-"\uE0A0"}
GEOMETRY_SYMBOL_GIT_UNPULLED=${GEOMETRY_SYMBOL_GIT_UNPULLED:-"⇣"}
GEOMETRY_SYMBOL_GIT_UNPUSHED=${GEOMETRY_SYMBOL_GIT_UNPUSHED:-"⇡"}
GEOMETRY_SYMBOL_GIT_CONFLICTS_SOLVED=${GEOMETRY_SYMBOL_GIT_CONFLICTS_SOLVED:-"◆"}
GEOMETRY_SYMBOL_GIT_CONFLICTS_UNSOLVED=${GEOMETRY_SYMBOL_GIT_CONFLICTS_UNSOLVED:-"◈"}

# Combine color and symbols
GEOMETRY_GIT_DIRTY=$(prompt_geometry_colorize $GEOMETRY_COLOR_GIT_DIRTY $GEOMETRY_SYMBOL_GIT_DIRTY)
GEOMETRY_GIT_CLEAN=$(prompt_geometry_colorize $GEOMETRY_COLOR_GIT_CLEAN $GEOMETRY_SYMBOL_GIT_CLEAN)
GEOMETRY_GIT_REBASE=$GEOMETRY_SYMBOL_GIT_REBASE
GEOMETRY_GIT_UNPULLED=$GEOMETRY_SYMBOL_GIT_UNPULLED
GEOMETRY_GIT_UNPUSHED=$GEOMETRY_SYMBOL_GIT_UNPUSHED
GEOMETRY_EXIT_VALUE=$(prompt_geometry_colorize $GEOMETRY_COLOR_EXIT_VALUE $GEOMETRY_SYMBOL_EXIT_VALUE)
GEOMETRY_PROMPT=$(prompt_geometry_colorize $GEOMETRY_COLOR_PROMPT $GEOMETRY_SYMBOL_PROMPT)

# Use ag if possible
GREP=$(command -v ag >/dev/null 2>&1 && echo "ag" || echo "grep")

prompt_geometry_git_branch() {
    ref=$(git symbolic-ref --short HEAD 2> /dev/null) || \
    ref=$(git rev-parse --short HEAD 2> /dev/null) || return
    echo "$(prompt_geometry_colorize $GEOMETRY_COLOR_GIT_BRANCH $ref)"
}

prompt_geometry_virtualenv() {
    if test ! -z $VIRTUAL_ENV; then
        local ref=$(basename $VIRTUAL_ENV) || return
        echo "$(prompt_geometry_colorize $GEOMETRY_COLOR_VIRTUALENV "(${ref})") "
    fi
}

prompt_geometry_git_status() {
    if test -z "$(git status --porcelain --ignore-submodules)"; then
        echo $GEOMETRY_GIT_CLEAN
    else
        echo $GEOMETRY_GIT_DIRTY
    fi
}

prompt_geometry_is_rebasing() {
    local git_dir=$(git rev-parse --git-dir)
    test -d "$git_dir/rebase-merge" -o -d "$git_dir/rebase-apply"
}

prompt_geometry_git_rebase_check() {
    if $(prompt_geometry_is_rebasing); then
        echo "$GEOMETRY_GIT_REBASE"
    fi
}

prompt_geometry_git_remote_check() {
    local local_commit=$(git rev-parse @ 2>&1)
    local remote_commit=$(git rev-parse @{u} 2>&1)
    local common_base=$(git merge-base @ @{u} 2>&1) # last common commit

    if [[ $local_commit == $remote_commit ]]; then
        echo ""
    else
        if [[ $common_base == $remote_commit ]]; then
            echo $GEOMETRY_GIT_UNPUSHED
        elif [[ $common_base == $local_commit ]]; then
            echo $GEOMETRY_GIT_UNPULLED
        else
            echo "$GEOMETRY_GIT_UNPUSHED $GEOMETRY_GIT_UNPULLED"
        fi
    fi
}

prompt_geometry_git_symbol() {
    echo "$(prompt_geometry_git_rebase_check) $(prompt_geometry_git_remote_check)"
}

prompt_geometry_git_conflicts() {
    conflicts=$(git diff --name-only --diff-filter=U)
    # echo adds a newline which we want to avoid
    # Using -n prevents from using wc, which searches for newlines
    # and returns 0 when a single file has conflicts
    # Use grep instead
    file_count=$(echo -n "$conflicts" | $GREP -c '^')

    # $file_count contains the amount of files with conflicts
    # in the **BEGINNING** of the merge/rebase.
    if [ "$file_count" -gt 0 ]; then
        # If we have fixed every conflict, $total will be empty
        # So we will check and mark it as good if every conflict is solved
        total=$($GREP -c '^=======$' $conflicts)

        if [[ -z $total ]]; then
            text=$GEOMETRY_SYMBOL_GIT_CONFLICTS_SOLVED
            color=$GEOMETRY_COLOR_GIT_CONFLICTS_SOLVED
        else
            text="$GEOMETRY_SYMBOL_GIT_CONFLICTS_UNSOLVED ($file_count|$total)"
            color=$GEOMETRY_COLOR_GIT_CONFLICTS_UNSOLVED
        fi

        echo "$(prompt_geometry_colorize $color $text) "
    else
        echo ""
    fi
}

prompt_geometry_git_info() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "$(prompt_geometry_git_symbol) $(prompt_geometry_git_branch) $conflicts::$time $(prompt_geometry_git_status)"
    fi
}

# Show current command in title
prompt_geometry_set_cmd_title() {
    local COMMAND="${2}"
    local CURR_DIR="${PWD##*/}"
    print -n '\e]0;'
    print -Pn '$COMMAND @ $CURR_DIR'
    print -n '\a'
}

# Prevent command showing on title after ending
prompt_geometry_set_title() {
    print -n '\e]0;'
    print -Pn '%~'
    print -n '\a'
}

prompt_geometry_render() {
    if [ $? -eq 0 ] ; then
        PROMPT_SYMBOL=$GEOMETRY_SYMBOL_PROMPT
    else
        PROMPT_SYMBOL=$GEOMETRY_SYMBOL_EXIT_VALUE
    fi

    PROMPT="%${#PROMPT_SYMBOL}{%(?.$GEOMETRY_PROMPT.$GEOMETRY_EXIT_VALUE)%} %F{$GEOMETRY_COLOR_DIR}%3~%f "

    PROMPT2="$GEOMETRY_SYMBOL_RPROMPT "
    RPROMPT="$(prompt_geometry_virtualenv)$(prompt_geometry_git_info)%f"
}

prompt_geometry_setup() {
    autoload -U add-zsh-hook

    add-zsh-hook preexec prompt_geometry_set_cmd_title
    add-zsh-hook precmd prompt_geometry_set_title
    add-zsh-hook precmd prompt_geometry_render
}

prompt_geometry_setup
