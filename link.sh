#!/bin/bash
declare -A TARGETS
TARGETS[nanorc.d]=.nanorc.d
TARGETS[xkb]=.xkb
TARGETS[gitconfig]=.gitconfig
TARGETS[install.apt]=.install.apt
TARGETS[nanorc]=.nanorc
TARGETS[redshift.conf]=.config/redshift.conf
TARGETS[remove.apt]=.remove.apt

for DOTFILE in "${!TARGETS[@]}"; do
    SRC="$HOME/Code/dotfiles/$DOTFILE"
    DST="$HOME/${TARGETS[$DOTFILE]}"
    if [[ ! -h $DST || `readlink $DST` != $SRC ]]; then
        echo "--- Linking $DST to $SRC"
        rm -rf "$DST"
        ln -s "$SRC" "$DST"
    fi
done
