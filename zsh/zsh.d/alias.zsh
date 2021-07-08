# Custom alias and functions for ZSH

# -------- Utilities ----------
_version_check() {
    # _version_check curver targetver: returns true (zero exit code) if $curver >= $targetver
    curver="$1"; targetver="$2";
    [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}
# -----------------------------

# Basic
alias reload!=". ~/.zshrc && echo 'sourced ~/.zshrc' again"
alias c='command'

alias cp='nocorrect cp -iv'
alias mv='nocorrect mv -iv'
alias rm='nocorrect rm -iv'

# sudo, but inherits $PATH from the current shell
alias sudoenv='sudo env PATH=$PATH'

if (( $+commands[htop] )); then
    alias top='htop'
    alias topc='htop -s PERCENT_CPU'
    alias topm='htop -s PERCENT_MEM'
fi

# list
if command -v exa 2>&1 >/dev/null; then
    # exa is our friend :)
    alias ls='exa'
    alias l='exa --long --group --git'
else
    # fallback to normal ls
    alias l='ls'
fi

# Screen
alias scr='screen -rD'

# vim: Defaults to Neovim if exists
if command -v nvim 2>&1 >/dev/null; then
    alias vim='nvim'
fi
alias vi='vim'
alias v='vim'

# Just open ~/.vimrc, ~/.zshrc, etc.
alias vimrc='vim +"cd ~/.dotfiles" +Vimrc +tabclose\ 1'
#alias vimrc='vim +cd\ ~/.vim -O ~/.vim/vimrc ~/.vim/plugins.vim'

alias zshrc='vim +cd\ ~/.zsh -O ~/.zsh/zshrc ~/.zsh/zsh.d/alias.zsh'

# Tmux ========================================= {{{

# tmuxa <session> : attach to <session> (force 256color and detach others)
alias tmuxa='tmux -2 attach-session -d -t'
# TMUX aliases
alias tm='tmux -u' #-u is for unicode functionality to rid of weird prompt space
alias ta='tmux attach -d' # the -d allows to detach any other clients when you attach, so the screen resolution is maintained
alias tls='tmux ls'
alias tat='tmux attach -d -t'
alias tns='tmux new-session -s'
alias tk='tmux kill-session -t'


# I am lazy, yeah
alias t='tmuxa'
alias T='TMUX= tmuxa'

# tmuxp
function tmuxp {
    tmuxpfile="$1"
    if [ -z "$tmuxpfile" ] && [[ -s ".tmuxp.yaml" ]]; then
        tmuxpfile=".tmuxp.yaml"
    fi

    if [[ -s "$tmuxpfile" ]]; then
        # (load) e.g. $ tmuxp [.tmuxp.yaml]
        command tmuxp load $tmuxpfile
    else
        # (normal commands)
        command tmuxp $@;
    fi
}

alias set-pane-title='set-window-title'
alias tmux-pane-title='set-window-title'

# }}}
# SSH ========================================= {{{

if [[ "$(uname)" == "Darwin" ]] && (( $+commands[iterm-tab-color] )); then
  ssh() {
    command ssh $@
    iterm-tab-color reset 2>/dev/null
  }
fi

function ssh-tmuxa {
    local host="$1"
    if [[ -z "$2" ]]; then
       ssh $host -t tmux attach -d
    else;
       ssh $host -t tmux attach -d -t "$2"
    fi
}
alias sshta='ssh-tmuxa'
alias ssh-ta='ssh-tmuxa'
compdef '_hosts' ssh-tmuxa
# }}}

# More Git aliases ============================= {{{
# (overrides prezto's default git/alias.zsh)

GIT_VERSION=$(git --version | awk '{print $3}')

alias gh='git history'
alias ghA='gh --all'
if _version_check $GIT_VERSION "2.0"; then
  alias gha='gh --exclude=refs/stash --all'
else
  alias gha='gh --all'   # git < 1.9 has no --exclude option
fi

alias gd='git diff --no-prefix'
alias gdc='gd --cached --no-prefix'
alias gds='gd --staged --no-prefix'
#alias gs='git status'
#alias gsu='gs -u'

function ghad() {
  # Run gha (git history) and refresh if anything in .git/ changes
  local GIT_DIR=$(git rev-parse --git-dir)
  local _command="clear; (date; echo ''; git history --all --color) \
    | head -n \$((\$(tput lines) - 2)) | less -FE"

  if [ `uname` == "Linux" ]; then
    which inotifywait > /dev/null || { echo "Please install inotify-tools."; return 1; }
    trap "break" SIGINT
    bash -c "$_command"
    while true; do
      inotifywait -q -q -r -e modify -e delete -e delete_self -e create -e close_write -e move \
        --exclude 'lock' "${GIT_DIR}/refs" "${GIT_DIR}/HEAD" || true;
      bash -c "$_command"
    done;

  else
    which fswatch > /dev/null || { echo "Please install fswatch."; return 1; }
    bash -c "$_command"
    fswatch -o "$GIT_DIR" \
        --exclude='.*' --include='HEAD$' --include='refs/' \
    | xargs -n1 -I{} bash -c "$_command" \
    || true   # exit code should be 0
  fi

  return 0
}

if alias gsd > /dev/null; then unalias gsd; fi
function gsd() {
  # Run gs (git status) and refresh if .git/index changes
  local GIT_DIR=$(git rev-parse --git-dir)
  local _command="clear; (date; echo ''; git status --branch $@)"

  if [ `uname` == "Linux" ]; then
    which inotifywait > /dev/null || { echo "Please install inotify-tools."; return 1; }
    trap "break" SIGINT
    bash -c "$_command"
    while true; do
      inotifywait -q -q -r -e modify -e delete -e delete_self -e create -e close_write -e move \
        "${GIT_DIR}/index" "${GIT_DIR}/refs" || true;
      bash -c "$_command"
    done;

  else
    which fswatch > /dev/null || { echo "Please install fswatch."; return 1; }
    bash -c "$_command"
    fswatch -o $(git rev-parse --git-dir)/index \
            --event=AttributeModified --event=Updated --event=IsFile \
        | xargs -n1 -I{} bash -c "$_command" \
    || true
  fi

  return 0
}

# using the vim plugin 'GV'!
function _vim_gv {
    vim -c ":GV $1"
}
alias gv='_vim_gv'
alias gva='gv --all'

# cd to $(git-root)
function cd-git-root() {
  local _root; _root=$(git-root)
  [ $? -eq 0 ] && cd "$_root" || return 1;
}

# }}}


# Python ======================================= {{{

# anaconda
alias sa='conda activate'   # source activate is deprecated.
alias ca='conda activate'
function deactivate() {
  # In anaconda/miniconda, use `conda deactivate`. In virtualenvs, `source deactivate`.
  # Note: deactivate could have been an alias, but legacy virtualenvs' shell scripts
  # are written wrong (i.e. missing `function`) as they have a conflict with the alias.
  [[ -n "$CONDA_DEFAULT_ENV" ]] && conda deactivate || source deactivate
}

# virtualenv
alias wo='workon'

# Make sure the correct python from $PATH is used for the binary, even if
# some the package is not installed in the current python environment.
# (Do not execute a wrong bin from different python such as the global one)
alias pip='python -m pip'
alias pip3='python3 -m pip'
alias mypy='python -m mypy'
alias pycodestyle='python -m pycodestyle'
alias pylint='python -m pylint'

# PREFIX/bin/python -> PREFIX/bin/ipython, etc.
alias ipdb='${$(which python)%/*}/ipdb'
alias pudb='${$(which python)%/*}/pudb3'
alias pudb3='${$(which python)%/*}/pudb3'
alias python-config='${$(which python)%/*}/python3-config'
alias python3-config='${$(which python)%/*}/python3-config'

# ipython
alias ipython='${$(which python)%/*}/ipython'
alias ipy='ipython'
alias ipypdb='ipy -c "%pdb" -i'   # with auto pdb calling turned ON

alias ipynb='jupyter notebook'
alias ipynb0='ipynb --ip=0.0.0.0'
alias jupyter='${$(which python)%/*}/jupyter'
alias jupyter-lab='${$(which python)%/*}/jupyter-lab --no-browser'

# ptpython
alias ptpython='${$(which python)%/*}/ptpython'
alias ptipython='${$(which python)%/*}/ptipython'
alias ptpy='ptipython'
alias pt='ptpy'

# pip install nose, rednose
alias nt='NOSE_REDNOSE=1 nosetests -v'

# unit test: in verbose mode
alias pytest='python -m pytest -vv'
alias pytest-pudb='pytest -s --pudb'
alias pytest-html='pytest --self-contained-html --html'
alias green='green -vv'

# some useful fzf-grepping functions for python
function pip-list-fzf() {
  pip list "$@" | fzf --header-lines 2 --reverse --nth 1 --multi | awk '{print $1}'
}
function pip-search-fzf() {
  if [[ -z "$1" ]]; then echo "argument required"; return 1; fi
  pip search "$@" | grep '^[a-z]' | fzf --reverse --nth 1 --multi --no-sort | awk '{print $1}'
}
function conda-list-fzf() {
  conda list "$@" | fzf --header-lines 3 --reverse --nth 1 --multi | awk '{print $1}'
}
function pipdeptree-fzf() {
  python -m pipdeptree "$@" | fzf --reverse
}
function pipdeptree-vim() {   # e.g. pipdeptree -p <package>
  python -m pipdeptree "$@" | vim - +"set ft=config foldmethod=indent" +"norm zR"
}

# }}}


# Some useful aliases for CLI scripting (pipe, etc)
alias awk1="awk '{print \$1}'"
alias awk2="awk '{print \$2}'"
alias awk3="awk '{print \$3}'"
alias awk4="awk '{print \$4}'"
alias awk5="awk '{print \$5}'"
alias awk6="awk '{print \$6}'"
alias awk7="awk '{print \$7}'"
alias awk8="awk '{print \$8}'"
alias awk9="awk '{print \$9}'"
alias awklast="awk '{print \$\(NF\)}'"


# Codes ===================================== {{{

alias prettyxml='xmllint --format - | pygmentize -l xml'

if (( $+commands[cdiff] )); then
    # cdiff, side-by-side with full width
    alias sdiff="cdiff -s -w0"
fi

# }}}

# Google Cloud ============================== {{{

function gcp-instances() {
  noglob gcloud compute instances list --filter 'name:'${1:-*} | less -F
}
function gcp-instances-fzf() {
  noglob gcloud compute instances list --filter 'name:'${1:-*} \
    | fzf --header-lines 1 --multi --reverse \
    | awk '{print $1}'
}

# }}}


# FZF magics ======================================= {{{

rgfzf () {
    # ripgrep
    if [ ! "$#" -gt 0 ]; then
        echo "Usage: rgfzf <query>"
        return 1
    fi
    rg --files-with-matches --no-messages "$1" | \
        fzf --prompt "$1 > " \
        --reverse --multi --preview "rg --ignore-case --pretty --context 10 '$1' {}"
}

# }}}

# Etc ======================================= {{{

alias iterm-tab-color="noglob iterm-tab-color"

if (( $+commands[pydf] )); then
    # pip install --user pydf
    # pydf: a colorized df
    alias df="pydf"
fi

function site-packages() {
    # print the path to the site packages from current python environment,
    # e.g. ~/.anaconda3/envs/XXX/lib/python3.6/site-packages/

    python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
    # python -c "import site; print('\n'.join(site.getsitepackages()))"
}

function vimpy() {
    # Open a corresponding file of specified python module.
    # e.g. $ vimpy numpy.core    --> opens $(site-package)/numpy/core/__init__.py
    if [[ -z "$1" ]]; then; echo "Argument required"; return 1; fi

    local _module_path=$(python -c "import $1; print($1.__file__)")
    if [[ -n "$module_path" ]]; then
      echo $module_path
      vim "$module_path"
    fi
}

# open some macOS applications
if [[ "$(uname)" == "Darwin" ]]; then

    # Force run under Rosetta 2 (for M1 mac)
    alias rosetta2='arch -x86_64'

    # brew for intel
    alias ibrew='arch -x86_64 /usr/local/bin/brew'

    # typora
    function typora   { open -a Typora "$@" }

    # skim
    function skim     { open -a Skim "$@" }
    compdef '_files -g "*.pdf"' skim

    # vimr
    function vimr     { open -a VimR "$@" }

    # terminal-notifier
    function notify   { terminal-notifier -message "$*" }

    # some commands that needs to work correctly in tmux
    if [ -n "$TMUX" ] && (( $+commands[reattach-to-user-namespace] )); then
        alias pngpaste='reattach-to-user-namespace pngpaste'
        alias pbcopy='reattach-to-user-namespace pbcopy'
        alias pbpaste='reattach-to-user-namespace pbpaste'
    fi
fi


# default watch options
alias watch='watch --color -n1'

# nvidia-smi/gpustat every 1 sec
#alias smi='watch -n1 nvidia-smi'
alias watchgpu='watch --color -n0.2 "gpustat --color || gpustat"'
alias smi='watchgpu'

function watchgpucpu {
    watch --color -n0.2 "gpustat --color; echo -n 'CPU '; cpu-usage | ascii-bar;"
}

function usegpu {
    local gpu_id="$1"
    if [[ "$1" == "none" ]]; then
        gpu_id=""
    elif [[ "$1" == "auto" ]] && (( $+commands[gpustat] )); then
        gpu_id=$(/usr/bin/python -c 'import gpustat, sys; \
            g = max(gpustat.new_query(), key=lambda g: g.memory_available); \
            g.print_to(sys.stderr); print(g.index)')
    fi
    export CUDA_DEVICE_ORDER=PCI_BUS_ID
    export CUDA_VISIBLE_DEVICES=$gpu_id
}

if (( ! $+commands[tb] )); then
    alias tb='python -m tbtools.tb'
fi

# LD_PRELOAD=/usr/lib/libtcmalloc.so.4 is to use a different memory malloc than what tensorflow normally uses. 
alias tfcpu="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=\"\" python"
alias tf0="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=0 python"
alias tf1="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=1 python"
alias tf2="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=2 python"
alias tf3="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=3 python"
alias tf4="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=4 python"
alias tf5="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=5 python"
alias tf6="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=6 python"
alias tf7="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=7 python"
alias tf012="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=0,1,2 python"
alias tf123="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=1,2,3 python"
alias tf0123="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=0,1,2,3 python"
alias tf1234="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=1,2,3,4 python"
alias tf4567="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=4,5,6,7 python"
alias tf01="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=0,1 python"
alias tf12="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=1,2 python"
alias tf23="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=2,3 python"
alias tf34="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=3,4 python"
alias tf45="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=4,5 python"
alias tf56="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=5,6 python"
alias tf67="LD_PRELOAD=/usr/lib/libtcmalloc.so.4 CUDA_VISIBLE_DEVICES=6,7 python"
alias py0="CUDA_VISIBLE_DEVICES=0 python"
alias py1="CUDA_VISIBLE_DEVICES=1 python"
alias py2="CUDA_VISIBLE_DEVICES=2 python"
alias py3="CUDA_VISIBLE_DEVICES=3 python"
alias py4="CUDA_VISIBLE_DEVICES=4 python"
alias py5="CUDA_VISIBLE_DEVICES=5 python"
alias py6="CUDA_VISIBLE_DEVICES=6 python"
alias py7="CUDA_VISIBLE_DEVICES=7 python"

# Num of files in current directory count.
alias count_files="ls -1U | wc -l"

alias count_frames="ffprobe -select_streams v -show_streams" # <add file_name> after.

# cd aliases
alias ..=".."
alias ...="../.."
alias ....="../../.."

alias iotop="sudo iotop"
alias gpukill="kill -9"

alias readonly="chmod 444"

# ctags
alias ctags="ctags -R --exclude=.git"


alias picasso="ssh -p7910 -L 127.0.0.1:6009:127.0.0.1:6009 -L 127.0.0.1:6008:127.0.0.1:6008 -L 127.0.0.1:6007:127.0.0.1:6007 -L 127.0.0.1:6006:127.0.0.1:6006 cdjkim@picasso.snu.vision"
alias davinci="ssh -p7910 dongjoo.kim@davinci.snu.vision"
#alias medici03="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 cdjkim@medici03.snu.vision"
alias medici03="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@147.46.219.57"
alias medici02="ssh -p7910 -L 127.0.0.1:7006:127.0.0.1:7006 -L 127.0.0.1:7007:127.0.0.1:7007 cdjkim@medici02.snu.vision"
alias medici01="ssh -p7910 -L 127.0.0.1:3006:127.0.0.1:3006 -L 127.0.0.1:3007:127.0.0.1:3007 cdjkim@medici01.snu.vision"
alias manet="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@manet.snu.vision"
alias miro="ssh -p7910 -L 127.0.0.1:4006:127.0.0.1:4006 cdjk@miro.snu.vision"
alias millet="ssh -p7910 -L 127.0.0.1:4006:127.0.0.1:4006 cdjkim@millet.snu.vision"
alias duchamp="ssh -p7910 -L 127.0.0.1:4006:127.0.0.1:4006 cdjkim@duchamp.snu.vision"
#alias rodin="ssh -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@147.46.15.107"
alias rodin="ssh -p7910 -L 127.0.0.1:5004:127.0.0.1:5004 -L 127.0.0.1:5003:127.0.0.1:5003 cdjkim@rodin.snu.vision"
alias hongdo="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@hongdo.snu.vision"
alias warhol="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@warhol.snu.vision"
alias dali="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@dali.snu.vision"
alias pollock="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@pollock.snu.vision"
alias gogh="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@gogh.snu.vision"
alias rembrandt="ssh -p7910 -L 127.0.0.1:4006:127.0.0.1:4006 -L 127.0.0.1:4007:127.0.0.1:4007 cdjkim@rembrandt.snu.vision"
alias namjune="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@namjune.snu.vision"
alias rubens="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@rubens.snu.vision"
alias monet="ssh -p7910 -L 127.0.0.1:5006:127.0.0.1:5006 -L 127.0.0.1:5007:127.0.0.1:5007 cdjkim@monet.snu.vision"


# to lock ubuntu from terminal
alias lock="gnome-screensaver-command -l"



# }}}
