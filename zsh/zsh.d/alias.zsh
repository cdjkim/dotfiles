# Custom Alias commands for ZSH

# Basic
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
alias vimrc='vim +Vimrc'
#alias vimrc='vim +cd\ ~/.vim -O ~/.vim/vimrc ~/.vim/plugins.vim'

alias zshrc='vim +cd\ ~/.zsh -O ~/.zsh/zshrc ~/.zpreztorc'

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
    host="$1"
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

alias gh='git history'
alias gha='gh --all'
alias gd='git diff --no-prefix'
alias gdc='gd --cached --no-prefix'
alias gds='gd --staged --no-prefix'
#alias gs='git status'
#alias gsu='gs -u'

# using the vim plugin 'GV'!
function _vim_gv {
    vim -c ":GV $1"
}
alias gv='_vim_gv'
alias gva='gv --all'

# }}}


# Python ======================================= {{{

# anaconda
alias sa='conda activate'   # source activate is deprecated.
alias ca='conda activate'
alias deactivate='[[ -n "$CONDA_DEFAULT_ENV" ]] && conda deactivate || deactivate'

# virtualenv
alias wo='workon'

# ipython
alias ipy='ipython'
alias ipypdb='ipy -c "%pdb" -i'   # with auto pdb calling turned ON

alias ipynb='jupyter notebook'
alias ipynb0='ipynb --ip=0.0.0.0'
alias jupyter-lab='jupyter-lab --no-browser'

# ptpython
alias ptpy='ptipython'

# pip install nose, rednose
alias nt='NOSE_REDNOSE=1 nosetests -v'

# unit test: in verbose mode
alias pytest='pytest -vv'
alias green='green -vv'

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

    module_path=$(python -c "import $1; print($1.__file__)")
    if [[ -n "$module_path" ]]; then
      echo $module_path
      vim "$module_path"
    fi
}

# open some macOS applications
if [[ "$(uname)" == "Darwin" ]]; then

    # typora
    function typora   { open -a Typora $@ }

    # skim
    function skim     { open -a Skim $@ }
    compdef '_files -g "*.pdf"' skim

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
    gpu_id="$1"
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





# }}}
