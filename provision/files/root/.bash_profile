
# use default settings
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# set git branch in command prompt
export PS1="\[\033[38m\]\u@\h\[\033[01;34m\] \w \[\033[31m\]\`ruby -e \"print (%x{git branch 2> /dev/null}.lines.grep(/^\*/).first || '').gsub(/^\* (.+)$/, '(\1) ')\"\`\[\033[37m\]$\[\033[00m\] "
