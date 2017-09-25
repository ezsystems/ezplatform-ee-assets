#! /bin/sh
# Script to prepare a ezplatform-ee-assets bundle release

[ ! -f "bin/prepare_release.sh" ] && echo "This script has to be run the root of the bundle" && exit 1

print_usage()
{
    echo "Create a new version of ezplatform-ee-assets bundle by creating a local tag"
    echo "This script MUST be run from the bundle root directory. It will create"
    echo "a tag but this tag will NOT be pushed"
    echo ""
    echo "Usage: $1 -v <version>"
    echo "-v version : where version will be used to create the tag"
}

VERSION=""
while getopts "hv:" opt ; do
    case $opt in
        v ) VERSION=$OPTARG ;;
        h ) print_usage "$0"
            exit 0 ;;
        * ) print_usage "$0"
            exit 2 ;;
    esac
done

[ -z "$VERSION" ] && print_usage "$0" && exit 2

check_command()
{
    $1 --version 2>&1 > /dev/null
    check_process "find '$1' in the PATH, is it installed?"
}

check_process()
{
    [ $? -ne 0 ] && echo "Fail to $1" && exit 3
}

check_command "git"
check_command "bower"

VENDOR_DIR=`cat .bowerrc | grep "directory" | cut -d ':' -f 2 | sed 's/[ "]//g'`
POSTSCRIBE_DIR="$VENDOR_DIR/postscribe-min"
POSTSCRIBE_NOTICE="$POSTSCRIBE_DIR/POSTSCRIBE_IN_EZPLATFORMEEASSETS.txt"
DRAGSTER_DIR="$VENDOR_DIR/dragsterjs"
DRAGSTER_NOTICE="$DRAGSTER_DIR/DRAGSTER_IN_EZPLATFORMEEASSETS.txt"
DATATABLE_DIR="$VENDOR_DIR/fixed-data-table"
DATATABLE_NOTICE="$DATATABLE_DIR/DATATABLE_IN_EZPLATFORMEEASSETS.txt"
REACT_DIR="$VENDOR_DIR/react"
REACT_NOTICE="$REACT_DIR/REACT_IN_EZPLATFORMEEASSETS.txt"

CURRENT_BRANCH=`git branch | grep '*' | cut -d ' ' -f 2`
TMP_BRANCH="version_$VERSION"
TAG="v$VERSION"

echo "# Switching to master and updating"
git checkout -q master > /dev/null && git pull > /dev/null
check_process "switch to master"

echo "# Removing the assets"
[ ! -d "$VENDOR_DIR" ] && mkdir -p $VENDOR_DIR
[ -d "$VENDOR_DIR" ] && rm -rf $VENDOR_DIR/*
check_process "clean the vendor dir $VENDOR_DIR"

echo "# Bower install"
npm install
bower install
npm run build
check_process "run bower"

echo "# Removing unused files from Fixed Data Table"
rm -rf "$DATATABLE_DIR/build_helpers" "$DATATABLE_DIR/docs" "$DATATABLE_DIR/examples" "$DATATABLE_DIR/site" "$DATATABLE_DIR/src" $DATATABLE_DIR/main.js $DATATABLE_DIR/webpack.config.js $DATATABLE_DIR/.babelrc $DATATABLE_DIR/.bower.json $DATATABLE_DIR/.editorconfig $DATATABLE_DIR/.gitignore $DATATABLE_DIR/.npmignore
check_process "clean fixed-data-table"
echo "This is a customized Fixed Data Table version." > $DATATABLE_NOTICE
echo "To decrease the size of the bundle, it does not include the library docs," >> $DATATABLE_NOTICE
echo "the examples, the source files, the build helpers or any development-only files." >> $DATATABLE_NOTICE

echo "# Removing unused files from DragsterJS"
rm -rf $DRAGSTER_DIR/.bower.json $DRAGSTER_DIR/bower.json $DRAGSTER_DIR/dragster-comment.js $DRAGSTER_DIR/dragster-script.js $DRAGSTER_DIR/module-generator.js $DRAGSTER_DIR/template.common.js $DRAGSTER_DIR/template.es6.js
check_process "clean dragsterjs"
echo "This is a customized DragsterJS version." > $DRAGSTER_NOTICE
echo "To decrease the size of the bundle, it does not include development-only files" >> $DRAGSTER_NOTICE

echo "# Removing unused files from react"
rm -rf $REACT_DIR/.bower.json $REACT_DIR/bower.json $REACT_DIR/react-dom-server.js $REACT_DIR/react-dom-server.min.js $REACT_DIR/react-with-addons.js $REACT_DIR/react-with-addons.min.js
check_process "clean react"
echo "This is a customized react version." > $REACT_NOTICE
echo "To decrease the size of the bundle, it does not include development-only files" >> $REACT_NOTICE

echo "# Creating the custom branch: $TMP_BRANCH"
git checkout -q -b "$TMP_BRANCH" > /dev/null
check_process "create the branch '$TMP_BRANCH'"

echo "# Commiting"
git add Resources > /dev/null
git commit -q -m "Version $VERSION"
check_process "commit the assets"

echo "# Tagging $TAG"
git tag "$TAG"
check_process "to tag the version '$TAG'"

echo "# Switching back to '$CURRENT_BRANCH'"
git checkout -q "$CURRENT_BRANCH" > /dev/null
check_process "to switch back to '$CURRENT_BRANCH'"

echo "# Removing the custom branch '$TMP_BRANCH'"
git branch -D "$TMP_BRANCH" > /dev/null
check_process "to remove the branch '$TMP_BRANCH'"

echo ""
echo "The tag '$TAG' has been created, please check that everything is correct"
echo "then you can run:"
echo "  git push origin $TAG"
echo "and create the corresponding release on Github"
echo "https://github.com/ezsystems/ezplatform-ee-assets/releases"
