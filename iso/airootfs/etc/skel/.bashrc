# pgOS user bashrc

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
    echo -e "  \e[1;34mpgOS\e[0m — 404: everything else, not found."
fi
