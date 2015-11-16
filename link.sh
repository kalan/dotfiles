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
TARGETS[theanorc]=.theanorc
TARGETS[octaverc]=.octaverc
TARGETS[i3.config]=.config/i3/config
TARGETS[sshconfig]=.ssh/config
TARGETS[hgrc]=.hgrc
TARGETS[fonts.conf]=.config/fontconfig/fonts.conf
TARGETS[Xresources]=.Xresources
TARGETS[jupyter.js]=.jupyter/custom/custom.js
TARGETS[jupyter_notebook_config.py]=.jupyter/jupyter_notebook_config.py
TARGETS[refsrc]=.config/refs/refsrc
TARGETS[hockey.lua]=.local/share/vlc/lua/sd/hockey.lua
TARGETS[emacs.service]=.config/systemd/user/emacs.service
TARGETS[emacsclient.desktop]=.local/share/applications/emacsclient.desktop

checkandlink () {
    SRC=$1
    DST=$2
    DIR=$(dirname $DST)

    if [ ! -d $DIR ]; then
        echo "--- Making directory '$DIR'"
        mkdir -p "$DIR"
    fi

    if [[ ! -h $DST || `readlink $DST` != $SRC ]]; then
        echo "--- Linking $DST to $SRC"
        rm -rf "$DST"
        if [[ $SRC == *".service" ]]; then
            # Special case due to systemd not allowing services to be symlinks
            ln "$SRC" "$DST"
        else
            ln -s "$SRC" "$DST"
        fi
    fi
}

for DOTFILE in "${!TARGETS[@]}"; do
    SRC="$HOME/Code/dotfiles/$DOTFILE"
    DST="$HOME/${TARGETS[$DOTFILE]}"
    checkandlink "$SRC" "$DST"
done
