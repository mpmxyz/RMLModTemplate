#!/usr/bin/env bash

cd "$( dirname "$0" )" || exit 1

VALID_GITHUB_NAME_PATTERN='^[a-zA-Z0-9_\.\-]+$'
VALID_RML_ID_PATTERN='^[a-zA-Z0-9_\.\-]+$'

##user input
OLD_AUTHOR_NAME='TODO_TemplateAuthor'
OLD_AUTHOR_PATTERN="$( printf %s "$OLD_AUTHOR_NAME" | sed -E 's/\W/\\\0/g' )"
read -p "Author name (previous: $OLD_AUTHOR_NAME):" -r NEW_AUTHOR_NAME || exit 2
if [[ ! "$NEW_AUTHOR_NAME" =~ $VALID_GITHUB_NAME_PATTERN ]]
then
  echo "Invalid author name: '$NEW_AUTHOR_NAME'" >&2
  exit 2
fi

OLD_RML_AUTHOR_ID='TODO_TemplateRMLAuthorID'
OLD_RML_AUTHOR_PATTERN="$( printf %s "$OLD_RML_AUTHOR_ID" | sed -E 's/\W/\\\0/g' )"
read -p "Author manifest ID (previous: $OLD_RML_AUTHOR_ID):" -r NEW_RML_AUTHOR_ID || exit 2
if [[ ! "$NEW_RML_AUTHOR_ID" =~ $VALID_RML_ID_PATTERN ]]
then
  echo "Invalid RML author ID: '$NEW_RML_AUTHOR_ID'" >&2
  exit 3
fi

OLD_MOD_NAME='TODO_TemplateModName'
OLD_MOD_PATTERN="$( printf %s "$OLD_MOD_NAME" | sed -E 's/\W/\\\0/g' )"
read -p "Mod name (previous: $OLD_MOD_NAME):" -r NEW_MOD_NAME || exit 3
if [[ ! "$NEW_MOD_NAME" =~ $VALID_GITHUB_NAME_PATTERN ]]
then
  echo "Invalid mod name: '$NEW_MOD_NAME'" >&2
  exit 4
fi

##sed argument preparation and side-effect validation
declare -a SED_ARGS
SED_ARGS=(-E)
if [ "$OLD_MOD_NAME" != "$NEW_MOD_NAME" ]
then
	SED_ARGS+=(-e "s/$OLD_MOD_PATTERN/$NEW_MOD_NAME/g")
fi
if [ "$OLD_RML_AUTHOR_ID" != "$NEW_RML_AUTHOR_ID" ]
then
	if [[ "$NEW_MOD_NAME" =~ $OLD_RML_AUTHOR_PATTERN ]]
	then
	  echo "Error: '$NEW_MOD_NAME' contains substring '$OLD_RML_AUTHOR_ID'!" >&2
	  echo " This would break replacements." >&2
	  echo " You can workaround by only changing the RML author ID in the first run, then the mod name!" >&2
	  exit 5
	fi

	SED_ARGS+=(-e "s/$OLD_RML_AUTHOR_PATTERN/$NEW_RML_AUTHOR_ID/g")
fi
if [ "$OLD_AUTHOR_NAME" != "$NEW_AUTHOR_NAME" ]
then
	if [[ "$NEW_MOD_NAME" =~ $OLD_AUTHOR_PATTERN ]]
	then
	  echo "Error: '$NEW_MOD_NAME' contains substring '$OLD_AUTHOR_NAME'!" >&2
	  echo " This would break replacements." >&2
	  echo " You can workaround by only changing the author in the first run, then the mod name!" >&2
	  exit 6
	fi
	if [[ "$NEW_RML_AUTHOR_ID" =~ $OLD_AUTHOR_PATTERN ]]
	then
	  echo "Error: '$NEW_RML_AUTHOR_ID' contains substring '$OLD_AUTHOR_NAME'!" >&2
	  echo " This would break replacements." >&2
	  echo " You can workaround by only changing the author in the first run, then the RML author ID!" >&2
	  exit 7
	fi

	SED_ARGS+=(-e "s/$OLD_AUTHOR_PATTERN/$NEW_AUTHOR_NAME/g")
fi

#go through directories and change file names in each directory (not in .git)
mapfile -d $'\0' DIRECTORIES < <( find . -depth -not -path './.git/*' -not -path './.git' -type d -print0 )
for DIR in "${DIRECTORIES[@]}"
do
	(
		if cd "$DIR"
		then
			unset CHILDREN
			mapfile -d $'\0' CHILDREN < <( find . -maxdepth 1 -mindepth 1 -print0 )
			for OLD_NAME in "${CHILDREN[@]}"
			do
				#Compute new name; suffix x is used to ensure no newline is lost for those weirdos creating multiline file names...
				NEW_NAME="$( printf %s "$OLD_NAME" | sed "${SED_ARGS[@]}" ; printf x )"
				NEW_NAME="${NEW_NAME%x}"
				if [ "$OLD_NAME" != "$NEW_NAME" ]
				then
					git mv "$OLD_NAME" "$NEW_NAME"
				fi
			done
		fi
	)
done

#replace file contents (not in .git)
find . -not -path './.git/*' -type f -exec sed -i "${SED_ARGS[@]}" {} +

echo "Setup complete! You can remove this file when you don't want to change names anymore."