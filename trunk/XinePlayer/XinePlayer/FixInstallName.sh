#!/bin/sh

# FixInstallName.sh
# XineKit
#
# Created by Rich Wareham on 10/02/2005.
# Copyright 2005 Rich Wareham. All rights reserved.
# Fix the install path of the xine dylib so that we can embed it in our framework.

cd $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH
#otool -L $EXECUTABLE_NAME
NAME=`otool -L $EXECUTABLE_NAME | grep "xine.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`
NEWNAME=`basename $NAME`
echo Changing $NAME in $EXECUTABLE_NAME ... 
cp $NAME ../Resources/$NEWNAME
install_name_tool -change $NAME @executable_path/../Resources/$NEWNAME $EXECUTABLE_NAME

cd $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH/../PlugIns/
for EXECUTABLE_NAME in `find . -name '*.so'`; do
NAME=`otool -L $EXECUTABLE_NAME | grep "xine.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`
NEWNAME=`basename $NAME`
echo Changing $NAME in $EXECUTABLE_NAME ... 
install_name_tool -change $NAME @executable_path/../Resources/$NEWNAME $EXECUTABLE_NAME
done

#otool -L $EXECUTABLE_NAME

# Do we have libdvdcss?
if [ -f /usr/lib/libdvdcss.2.dylib ]; then
  cp /usr/lib/libdvdcss.2.dylib $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH/../PlugIns/XinePlugins/libdvdcss.so.2
fi
