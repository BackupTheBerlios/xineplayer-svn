#!/bin/sh

# FixInstallName.sh
# XineKit
#
# Created by Rich Wareham on 10/02/2005.
# Copyright 2005 Rich Wareham. All rights reserved.
# Fix the install path of the xine dylib so that we can embed it in our framework.

cd $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH
otool -L $EXECUTABLE_NAME
NAME=`otool -L $EXECUTABLE_NAME | grep "xine.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`
NEWNAME=`basename $NAME`
echo Changing $NAME ... 
install_name_tool -change $NAME @executable_path/../Resources/$NEWNAME $EXECUTABLE_NAME
otool -L $EXECUTABLE_NAME
