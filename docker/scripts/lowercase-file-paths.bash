#!/bin/bash

# Lowercase leaf node of file and folder names
find -L "$1" -depth | while read -r file; do
    # Get the directory path and the leaf node
    dir=$(dirname "$file")
    leaf=$(basename "$file")

    # Get the new lowercase leaf node
    lowercase_leaf=$(echo "$leaf" | tr '[:upper:]' '[:lower:]')

    # Rename the file/folder if necessary
    if [ "$leaf" != "$lowercase_leaf" ]; then
        mv "$file" "$dir/$lowercase_leaf"
    fi
done
