#!/usr/bin/env bash

# Install ASDF
if [ ! -d "${HOME}/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch v0.11.1
fi
