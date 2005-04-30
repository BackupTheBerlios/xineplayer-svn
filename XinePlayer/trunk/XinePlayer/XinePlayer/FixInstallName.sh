#!/bin/bash

# FixInstallName.sh
# XineKit
#
# Created by Rich Wareham on 10/02/2005.
# Copyright 2005 Rich Wareham. All rights reserved.
# Fix the install path of the xine dylib so that we can embed it in our framework.

cd $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH

PLUGINS_LIBPATH=@executable_path/../PlugIns/XinePlugins/

# Fix the actual XinePlayer binary
NAME=`otool -L $EXECUTABLE_NAME | grep "^[^@]*xine.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`
NEWNAME=`basename $NAME`
echo Changing $NAME in $EXECUTABLE_NAME ... 
install_name_tool -change $NAME $PLUGINS_LIBPATH/$NEWNAME $EXECUTABLE_NAME
cp $NAME $PWD/../PlugIns/XinePlugins/$NEWNAME

# Now fix each plugin...
for PLUGIN_NAME in `find $PWD/../PlugIns/XinePlugins/ -name '*.so'`; do
        #  ...firstly fix the libxine reference.
        NAME=`otool -L $PLUGIN_NAME | grep "^[^@]*xine.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`
        NEWNAME=`basename $NAME`
        echo Changing $NAME in $PLUGIN_NAME ... 
        install_name_tool -change $NAME $PLUGINS_LIBPATH/$NEWNAME $PLUGIN_NAME

        # ...and copy any dependant libraries.
        for LIBNAME in `otool -L $PLUGIN_NAME | grep "/sw/[^@]*\.dylib " | cut -f 2 | cut -f 1 -d ' '`; do
                if [ ! -z $LIBNAME ]; then
                        echo Changing $LIBNAME in $PLUGIN_NAME
                        NEWNAME=`basename $LIBNAME`
                        if [ "x$NEWNAME" == "xlibiconv.2.dylib" ]; then
                                install_name_tool -change $LIBNAME /usr/lib/$NEWNAME $PLUGIN_NAME
                        else
                                install_name_tool -change $LIBNAME $PLUGINS_LIBPATH/$NEWNAME $PLUGIN_NAME
                                echo ...and copying
                                cp $LIBNAME $PWD/../PlugIns/XinePlugins/$NEWNAME
                        fi
                fi
        done
done

# Do we have libdvdcss? If so, copy it.
if [ -f /usr/lib/libdvdcss.2.dylib ]; then
  cp /usr/lib/libdvdcss.2.dylib $BUILD_ROOT/$EXECUTABLE_FOLDER_PATH/../PlugIns/XinePlugins/libdvdcss.so.2
fi

# Now let's try fixing the copied libraries
for LIBRARY_NAME in $PWD/../PlugIns/XinePlugins/lib*; do
        # Fix the /sw/... links
        for LIBNAME in `otool -L $LIBRARY_NAME | grep "/sw/.*\.dylib " | cut -f 2 | cut -f 1 -d ' '`; do
                if [ ! -z $LIBNAME ]; then
                        echo Changing $LIBNAME in $LIBRARY_NAME
                        NEWNAME=`basename $LIBNAME`
                        if [ "x$NEWNAME" == "xlibiconv.2.dylib" ]; then
                                install_name_tool -change $LIBNAME /usr/lib/$NEWNAME $LIBRARY_NAME
                        else
                                install_name_tool -change $LIBNAME $PLUGINS_LIBPATH/$NEWNAME $LIBRARY_NAME
                        
                                # We may still have some odd things. Print warnings for such
                                if [ ! -f $PWD/../PlugIns/XinePlugins/$NEWNAME ]; then
                                        echo "WARNING: $NEWNAME has not been copied!"
                                fi
                        fi
                fi
        done
done
