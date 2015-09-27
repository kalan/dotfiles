#!/usr/bin/env bash
declare -A TARGETS
TARGETS[nanorc.d]=.nanorc.d
TARGETS[xkb]=.xkb
TARGETS[gitconfig]=.gitconfig
TARGETS[install.apt]=.install.apt
TARGETS[install.brew]=.install.brew
TARGETS[nanorc]=.nanorc
TARGETS[redshift.conf]=.config/redshift.conf
TARGETS[remove.apt]=.remove.apt
TARGETS[remove.brew]=.remove.brew
TARGETS[rtorrent.rc]=.rtorrent.rc
TARGETS[sshconfig]=.ssh/config
TARGETS[hgrc]=.hgrc
TARGETS[fonts.conf]=.config/fontconfig/fonts.conf
TARGETS[jupyter.js]=.jupyter/custom/custom.js

checkandlink () {
    SRC=$1
    DST=$2
    if [[ ! -h $DST || `readlink $DST` != $SRC ]]; then
        echo "--- Linking $DST to $SRC"
        rm -rf "$DST"
        ln -s "$SRC" "$DST"
    fi
}

for DOTFILE in "${!TARGETS[@]}"; do
    SRC="$HOME/Code/dotfiles/$DOTFILE"
    DST="$HOME/${TARGETS[$DOTFILE]}"
    checkandlink "$SRC" "$DST"
done
