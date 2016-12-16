#!/bin/sh

##################################################################

Parallel_Make () {
    local numprocs=1
    case $OS in
    'linux')
        numprocs=`grep -c ^processor /proc/cpuinfo 2>/dev/null`
        ;;
    'mac')
        if type sysctl &> /dev/null; then
            numprocs=`sysctl -n hw.ncpu`
        fi
        ;;
    #"solaris')
    #    on Solaris you need to use psrinfo -p instead
    #    ;;
    #'freebsd')
    #    ;;
    *) ;;
    esac
    if [ "$numprocs" = "" ] || [ "$numprocs" = "0" ]; then
        numprocs=1
    fi
    make -s -j$numprocs
}

##################################################################
# Init

Home=`pwd`
ZenLib_Options=""
MacOptions="--with-macosx-version-min=10.5"

OS=$(uname -s)
# expr isn't available on mac
if [ "$OS" = "Darwin" ]; then
    OS="mac"
    IMPLEMENTATION_BINARY="MediaConch.app/Contents/MacOS/MediaConch-Implementation"
    POLICY_BINARY="MediaConch.app/Contents/MacOS/MediaConch-Policy"
    if test -d ~/Qt/5.3/clang_64/bin; then
        export PATH=$PATH:~/Qt/5.3/clang_64/bin
    fi  
# if the 5 first caracters of $OS equal "Linux"
elif [ "$(expr substr $OS 1 5)" = "Linux" ]; then
    OS="linux"
    IMPLEMENTATION_BINARY="mediaconch-implementation-gui"
    POLICY_BINARY="mediaconch-policy-gui"
fi

##################################################################
# Configure ZenLib

if test -e ZenLib/Project/GNU/Library/configure; then
    cd ZenLib/Project/GNU/Library/
    test -e Makefile && rm Makefile
    chmod +x configure
    if [ "$OS" = "mac" ]; then
        ./configure --enable-static --disable-shared $MacOptions $ZenLib_Options $*
    else
        ./configure --enable-static --disable-shared $ZenLib_Options $*
    fi
    if test ! -e Makefile; then
        echo Problem while configuring ZenLib
        exit
    fi
else
    echo ZenLib directory is not found
    exit
fi
cd $Home

##################################################################
# Compile ZenLib

cd ZenLib/Project/GNU/Library/
make clean
Parallel_Make
if test -e libzen.la; then
    echo ZenLib compiled
else
    echo Problem while compiling ZenLib
    exit
fi
cd $Home

##################################################################
# Configure MediaInfoLib

if test -e MediaInfoLib/Project/GNU/Library/configure; then
    cd MediaInfoLib/Project/GNU/Library/
    test -e Makefile && rm Makefile
    chmod +x configure
    if [ "$OS" = "mac" ]; then
        ./configure --enable-static --disable-shared $MacOptions --with-libcurl=runtime $*
    else
        ./configure --enable-static --disable-shared --with-libcurl $*
    fi
    if test ! -e Makefile; then
        echo Problem while configuring MediaInfoLib
        exit
    fi
else
    echo MediaInfoLib directory is not found
    exit
fi
cd $Home

##################################################################
# Configure MediaConch-Policy

if test -e MediaConch-Policy/Project/Qt/prepare; then
    cd MediaConch-Policy/Project/Qt/
    test -e Makefile && rm Makefile
    chmod +x prepare
    ./prepare STATIC_LIBS=1
    if test ! -e Makefile; then
        echo "Problem while configuring MediaConch-Policy (GUI)"
        exit
    fi
else
    echo MediaConch-Policy directory is not found
    exit
fi
cd $Home

if test -e MediaConch-Implementation/Project/Qt/prepare; then
    cd MediaConch-Implementation/Project/Qt/
    test -e Makefile && rm Makefile
    chmod +x prepare
    ./prepare STATIC_LIBS=1
    if test ! -e Makefile; then
        echo "Problem while configuring MediaConch-Implementation (GUI)"
        exit
    fi
else
    echo MediaConch-Implementation directory is not found
    exit
fi
cd $Home

##################################################################
# Compile MediaInfoLib

cd MediaInfoLib/Project/GNU/Library
make clean
Parallel_Make
if test -e libmediainfo.la; then
    echo MediaInfoLib compiled
else
    echo Problem while compiling MediaInfoLib
    exit
fi
cd $Home

##################################################################
# Compile MediaConch

cd MediaConch-Implementation/Project/Qt
make clean
Parallel_Make
if test -e $IMPLEMENTATION_BINARY; then
    echo "MediaConch-Implementation (GUI) compiled"
else
    echo "Problem while compiling-Implementation MediaConch (GUI)"
    exit
fi
cd $Home

cd MediaConch-Policy/Project/Qt
make clean
Parallel_Make
if test -e $POLICY_BINARY; then
    echo "MediaConch-Policy (GUI) compiled"
else
    echo "Problem while compiling-Policy MediaConch (GUI)"
    exit
fi
cd $Home

##################################################################

echo "MediaConch-Implementation executable is MediaConch-Implementation/Project/Qt/$IMPLEMENTATION_BINARY"
echo "MediaConch-Policy executable is MediaConch-Policy/Project/Qt/$POLICY_BINARY"

unset -v Home ZenLib_Options MacOptions OS BINARY
