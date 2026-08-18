#!/usr/bin/env bash

BUILD_PATH="$(realpath "$( dirname "$0" )")"
BUILD_NAME="$(basename -- *.slnx .slnx)"
export ResonitePath="$BUILD_PATH/ResoniteAssemblies/"

#The default will make the build script testable outside of a GitHub workflow.
REPOSITORY_OWNER=${GITHUB_REPOSITORY_OWNER:-TODO_TemplateAuthor}

# setup Resonite's reference assemblies
mkdir -p "$ResonitePath" && cd "$ResonitePath" || exit 1
if ! wget "https://raw.githubusercontent.com/$REPOSITORY_OWNER/ResoniteAssemblies/refs/heads/main/Assemblies.zip"
then
	echo "Make sure you own a fork of https://github.com/mpmxyz/ResoniteAssemblies!" >&2
	echo "While it would be possible to depend on someone else's fork it can be maintained easily without being dependent on other people's actions." >&2
	exit 2
fi
unzip Assemblies.zip || exit 3
cd "$BUILD_PATH" || exit 4

# download packages
dotnet restore || exit 5

# build
dotnet build --no-restore --configuration Release || exit 6

# test
dotnet test --no-restore --no-build || exit 7

# package as zip file
cd "$ResonitePath" || exit 8
zip "$BUILD_NAME.zip" rml_mods/*.dll