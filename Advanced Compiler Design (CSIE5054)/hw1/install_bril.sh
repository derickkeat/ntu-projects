#!/bin/bash

# TODO: Add the commands to install the Bril environment tools.
# Make sure your script installs Deno, Flit, and the Bril tools.
# Ensure the script works on any machine and sets up the PATH correctly.

# Install Deno
npm install -g deno

# Add Deno to PATH for this session
export PATH="$PATH:$HOME/.deno/bin"

# Install brili (Bril interpreter)
cd bril
deno install --allow-read --allow-write brili.ts
cd ..

# Install Flit
pip install --user flit

# Install bril2json and bril2txt from bril-txt directory
cd bril/bril-txt
flit install --symlink --user