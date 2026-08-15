#!/usr/bin/env bash

cd "$( dirname $0 )" || exit 1

VALID_GITHUB_NAME_PATTERN='^[a-zA-Z0-9_\.\-]+$'

OLD_AUTHOR_NAME='TODO_TemplateAuthor'
OLD_AUTHOR_PATTERN="$( printf %s "$OLD_AUTHOR_NAME" | sed -E 's/\W/\\\0/g' )"
read -p "Author name (previous: $OLD_AUTHOR_NAME):" -r NEW_AUTHOR_NAME || exit 2
if [[ ! "$NEW_AUTHOR_NAME" =~ $VALID_GITHUB_NAME_PATTERN ]]
then
  echo "Invalid author name: '$NEW_AUTHOR_NAME'" >&2
  exit 2
fi

OLD_MOD_NAME='TODO_TemplateModName'
OLD_MOD_PATTERN="$( printf %s "$OLD_MOD_NAME" | sed -E 's/\W/\\\0/g' )"
read -p "Mod name (previous: $OLD_MOD_NAME):" -r NEW_MOD_NAME || exit 3
if [[ ! "$NEW_MOD_NAME" =~ $VALID_GITHUB_NAME_PATTERN ]]
then
  echo "Invalid mod name: '$NEW_MOD_NAME'" >&2
  exit 3
fi
REPLACE_MOD_NAME="s/$OLD_MOD_PATTERN/$NEW_MOD_NAME/g"

if [[ "$NEW_MOD_NAME" =~ $OLD_AUTHOR_PATTERN ]]
then
  echo "Error: '$NEW_MOD_NAME' contains substring '$OLD_AUTHOR_NAME'!" >&2
  echo " This would break replacements." >&2
  echo " You can workaround by only changing the author in the first run, then the mod name!" >&2
  exit 4
fi
REPLACE_AUTHOR_NAME="s/$OLD_AUTHOR_PATTERN/$NEW_AUTHOR_NAME/g"

mapfile -d $'\0' DIRECTORIES < <( find . -depth -not -path './.git/*' -not -path './.git' -type d -print0 )
for DIR in "${DIRECTORIES[@]}"
do
  (
    cd "$DIR"
    unset CHILDREN
    mapfile -d $'\0' CHILDREN < <( find -maxdepth 1 -mindepth 1 -print0 )
    for OLD_NAME in "${CHILDREN[@]}"
    do
      #Compute new name; suffix x is used to ensure no newline is lost for those weirdos creating multiline file names...
      NEW_NAME="$( printf %s "$OLD_NAME" | sed -E -e "$REPLACE_MOD_NAME" -e "$REPLACE_AUTHOR_NAME" ; printf x )"
      NEW_NAME="${NEW_NAME%x}"
      if [ "$OLD_NAME" != "$NEW_NAME" ]
      then
        mv "$OLD_NAME" "$NEW_NAME"
      fi
    done
  )
done

find . -not -path '.git/*' -type f -exec sed -E -i -e "$REPLACE_MOD_NAME" -e "$REPLACE_AUTHOR_NAME" {} +
