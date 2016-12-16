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
# if the 5 first caracters of $OS equal "Linux"
elif [ "$(expr substr $OS 1 5)" = "Linux" ]; then
    OS="linux"
#elif [ "$(expr substr $OS 1 5)" = "SunOS" ]; then
#    OS="solaris"
#elif [ "$(expr substr $OS 1 7)" = "FreeBSD" ]; then
#    OS="freebsd"
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
# Configure MediaConch

if test -e MediaConch-Policy/Project/GNU/Server/configure; then
    cd MediaConch-Policy/Project/GNU/Server/
    test -e Makefile && rm Makefile
    chmod +x configure
    if [ "$OS" = "mac" ]; then
        ./configure $MacOptions --enable-staticlibs $*
    else
        ./configure --enable-staticlibs $*
    fi
    if test ! -e Makefile; then
        echo "Problem while configuring MediaConch (Server)"
        exit
    fi
else
    echo MediaConch-Policy directory is not found
    exit
fi
cd $Home

##################################################################
# Compile MediaInfoLib

cd MediaInfoLib/Project/GNU/Library/
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

cd MediaConch-Policy/Project/GNU/Server/
make clean
Parallel_Make
if test -e mediaconchd; then
    echo "MediaConch (Server) compiled"
else
    echo "Problem while compiling MediaConch (Server)"
    exit
fi
cd $Home

##################################################################

echo "MediaConch Server executable is MediaConch-Policy/Project/GNU/Server/mediaconchd"
echo "For installing, cd MediaConch-Policy/Project/GNU/Server && make install"

unset -v Home ZenLib_Options MacOptions OS
