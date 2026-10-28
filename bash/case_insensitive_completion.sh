# If ~/.inputrc doesn't exist yet: First include the original /etc/inputrc
# so it won't get overriden
if [ ! -e ~/.inputrc ]; then echo '$include /etc/inputrc' > ~/.inputrc; fi

# Add shell-option to ~/.inputrc to enable case-insensitive tab completion (once)
grep -qxF 'set completion-ignore-case On' ~/.inputrc || echo 'set completion-ignore-case On' >> ~/.inputrc
