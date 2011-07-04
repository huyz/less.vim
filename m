#!/bin/sh
# Filename:         m
# Version:          0.2
# Description:
#   Pages through files as with `less` but with `vim` instead, giving you vim's
#   full colored syntax highlighting and vim commands if you need them.
#   Even standard input gets syntax highlighting, if recognizable.
#   It also acts as `less -F` and quits out immediately if a single file
#   has less than a screenful.
#   This file itself is an improved version of less.sh that is distributed with
#   vim.
#
# Platforms:        GNU/Linux, Mac OS X, Windows Cygwin (not yet tested)
# Depends:          vim
# Source:           https://github.com/huyz/less.vim
# Author:           Huy Z  http://huyz.us/
# Updated on:       2011-07-04
# Created on:       2002-07-05
#
# Installation:
# 1. Install a recent vim, if necessary
# 2. Move or symlink 'm' into your path
# 3. Move or symlink 'less.vim' into the same directory as 'm' or
#    into your ~/.vim/macros directory
#
# Usage:
# - To page through one or more files:
#   m file...
# - To page standard input, just pipe as usual:
#   grep function ~/.zshrc | m
# - Hit 'h' to see help; key mappings are similar to `less`
#
# TODO:
# - also quit immediately if stdin is less than a screenful.

# Copyright (C) 2011 Huy Z
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#############################################################################

# Default is to invoke vim
mode=vim

### Invoke

# 2011-07-03 Deprecated: we can make vim do everything we need now
# Invoke regular pager
# -r : handles ANSI color sequences
# -e : exits second time hit end of file
# -F : exits if less than screenful
#[ "$mode" = pager ] && LESS="${zsh_less_flags--diMQXj3z-3reF}" exec ${PAGER-less} "$@"

# If on terminal
if [ -t 1 ]; then

  # If only one argument and the file is small, we want to quit immediately after
  # displaying file, like `less -F` does
  if [ $# -eq 1 ]; then
    [ -n "$LINES" ] || LINES=$(stty size | cut -f1 "-d ")
    if [ -n "$LINES" ]; then
      if [ -r "$1" ]; then
        # CursorHold is to delay the quit long enough to display the text.
        [ $(wc -l "$1" | sed -n 's/^ *\([0-9][0-9]*\).*/\1/p') -lt "$LINES" ] && \
          set -- -c 'set t_ti= t_te= updatetime=100 | au! CursorHold * exe "quit"' "$@"
      fi
    fi

  # Standard input
  elif [ $# -eq 0 ]; then
    set -- -
  fi

  # Try to find less.vim
  [ -z "$MEHOME" ] && MEHOME=$HOME
  case "$0" in
    */*) arg0=$0 ;;
      *) arg0=$(which $0) ;;
  esac
  MACRO="${arg0%/m}/less.vim"
  if [ -r "$MACRO" ]; then
    MACRO="so $MACRO"
  elif [ -r "$MEHOME/.vim/macros/less.vim" ]; then
    # Macro location: try to find my modified less.vim first
    MACRO="so $MEHOME/.vim/macros/less.vim"
  else
    MACRO=
    # huyz 2011-07-04 This is just for me -- just ignore it
    if hash mehome >& /dev/null; then
      # Macro location: continue to try to find my modified less.vim
      MEHOME=`mehome`
      if [ -r "$MEHOME/.vim/macros/less.vim" ]; then
        MACRO="so $MEHOME/.vim/macros/less.vim"
      fi
    fi
    # Default to distribution
    if [ -z "$MACRO" ]; then
      MACRO='runtime! macros/less.vim'
    fi
  fi

  # - Set options here that shouldn't be set for everyone in less.vim, e.g.
  #   override potentially troublesome options from your ~/.vimrc:
  #   Turn off any statusbars, make searches case-smart, have normal tabstop.
  # - no_plugin_maps: that's from distribution example; assume it turns off
  #   mappings from plugins.
  # - --noplugin: actually, i want to disable plugins entirely because they're
  #   getting in the way, minibufexpl for example.
  DISPLAY= exec vim -R \
            --cmd 'let no_plugin_maps = 1' \
            --noplugin \
            -c 'nmap <ESC>u :nohlsearch<cr>' \
            -c 'set laststatus=0 ignorecase smartcase ts=8' \
            -c "$MACRO" \
            "$@"

else # No terminal
  exec cat "$@"
fi
