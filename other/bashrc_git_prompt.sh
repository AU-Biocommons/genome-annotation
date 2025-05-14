# add git branch info to prompt if inside a git repo
function parse_git_branch
{
#       ref=$(git symbolic-ref HEAD 2> /dev/null) || return
#       #echo "("${ref#refs/heads/}")"
       # Note:  this requires Bash programmable completion features enabled
       echo $(__git_ps1 " (%s)")
}

# add GIT branch (if in a Git repo) to end of prompt and show repo status
if [ -f /etc/bash_completion.d/git-prompt ]; then
#if [ -f /usr/share/git/git-prompt.sh ]; then
    #source /usr/share/git/git-prompt.sh
    source /etc/bash_completion.d/git-prompt
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    PS1="\u@\h \W\[\033[01;30m\]\$(parse_git_branch)\[\033[00m\]"
    PS1="$PS1\$ "
fi

