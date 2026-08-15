#!/usr/bin/env bash

BUILD_PATH="$(realpath $( dirname "$0" ))"
BUILD_NAME="$(basename *.slnx .slnx)"
export ResonitePath="$BUILD_PATH/ResoniteAssemblies/"

# setup Resonite's reference assemblies
mkdir -p "$ResonitePath" && cd "$ResonitePath" || exit 1
wget https://raw.githubusercontent.com/TODO_TemplateAuthor/ResoniteAssemblies/refs/heads/main/Assemblies.zip || exit 2
unzip Assemblies.zip || exit 3
cd "$BUILD_PATH" || exit 4

# download packages
dotnet restore || exit 5

# build
dotnet build --no-restore --configuration Release || exit 6

# test
dotnet test --no-restore --no-build || exit 7

# package as zip file
cd "$ResonitePath/rml_mods" || exit 8
zip "$BUILD_NAME.zip" *.dll