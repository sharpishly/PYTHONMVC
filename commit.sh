#!/bin/bash

line='----------------------------  '
clear


if [ -z "$1" ]; then
  echo "Error: Commit message is required."
  exit 1
fi


echo "$line Start commit"

# Dynamically change ownership of the current directory to the current user
echo "$line Change ownership of current folder"
sudo chown "$USER" -R "$(pwd)"

echo "$line Add all files"
git add .

echo "$line Add commit message"
git commit -m "${1}"

echo "$line Push code to repository"
git push

echo "$line Get Status"
git status

echo "$line Get log"
git log --oneline --graph --decorate



