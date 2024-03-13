# Run SSH agent
eval "$(ssh-agent -s)"

# Iterate through ~/.ssh/ and add all keys to the SSH agent
for key_file in ~/.ssh/*; do
    # Check if the file is
    # - a regular file (not a directory)
    # - is a key file type id_ed25519 or id_rsa
    # - and does not have a ".pub" extension
    if [ -f "$key_file" ] && [[ "$key_file" != *.pub ]] && { [[ "$key_file" == *id_ed25519* ]] || [[ "$key_file" == *id_rsa* ]]; }; then
        echo "Found key $key_file"
        # Add the key to the SSH agent
        ssh-add "$key_file"
        echo "Added $key_file to the SSH agent"
    fi
done