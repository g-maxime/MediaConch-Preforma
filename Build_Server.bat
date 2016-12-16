@echo off

rem *** Init ***

rem save old path
set OLD_PATH=%PATH%
set OLD_CD=%CD%

rem make output dir
set OUTDIR=MediaConch-Server
mkdir %OUTDIR%

rem set env
set MAKE=mingw32-make
set BASH=%CD%\buildenv01\usr\bin\bash --login -c
set MSYSTEM=MINGW32
set CXXFLAGS=-static -DNTDDI_VERSION=0x06000000 -D_WIN32_WINNT=0x0600

rem initialize bash user files (needed to make CHERE_INVOKING work)
%BASH% "exit"

set CHERE_INVOKING=1

if exist mediaconch_AllInclusive\ZenLib\Project\GNU\Library\.libs\libzen.a goto :mediainfolib

rem *** Configure ZenLib ***
pushd mediaconch_AllInclusive\ZenLib\Project\GNU\Library
	%BASH% "autoreconf -i"
	%BASH% "./configure --enable-static --disable-shared"
popd
if not exist mediaconch_AllInclusive\ZenLib\Project\GNU\Library\Makefile (
	echo ERROR: while ZenLib configure
	goto :clean
)

rem *** Build ZenLib ***
pushd mediaconch_AllInclusive\ZenLib\Project\GNU\Library
	%BASH% "%MAKE%"
popd
if not exist mediaconch_AllInclusive\ZenLib\Project\GNU\Library\.libs\libzen.a (
	echo ERROR: while ZenLib build
	goto :clean
)

:mediainfolib
if exist mediaconch_AllInclusive\MediaInfoLib\Project\GNU\Library\.libs\libmediainfo.a goto :mediaconch

rem *** Configure MediaInfoLib ***
pushd mediaconch_AllInclusive\MediaInfoLib\Project\GNU\Library
	%BASH% "autoreconf -i"
	%BASH% "./configure --enable-static --disable-shared --with-libcurl=runtime"
popd
if not exist mediaconch_AllInclusive\MediaInfoLib\Project\GNU\Library\Makefile (
	echo ERROR: while MediaInfoLib configure
	goto :clean
)

rem *** Build MediaInfoLib ***
pushd mediaconch_AllInclusive\MediaInfoLib\Project\GNU\Library
	%BASH% "%MAKE%"
popd
if not exist mediaconch_AllInclusive\MediaInfoLib\Project\GNU\Library\.libs\libmediainfo.a (
	echo ERROR: while MediaInfolIb build
	goto :clean
)

:mediaconch
rem *** Configure MediaConch Server ***
pushd mediaconch_AllInclusive\MediaConch-Policy\Project\GNU\Server
	%BASH% "autoreconf -i"
	%BASH% "LDFLAGS='-lole32 -luuid' ./configure --enable-staticlibs"
popd
if not exist mediaconch_AllInclusive\MediaConch-Policy\Project\GNU\Server\Makefile (
	echo ERROR: while MediaConch Server configure
	goto :clean
)

rem *** Build MediaConch Server ***
pushd mediaconch_AllInclusive\MediaConch-Policy\Project\GNU\Server
	%BASH% "%MAKE%"
popd
if not exist mediaconch_AllInclusive\MediaConch-Policy\Project\GNU\Server\mediaconchd.exe (
	echo ERROR: while MediaConch Server build
	goto :clean
)
copy mediaconch_AllInclusive\MediaConch-Policy\Project\GNU\Server\mediaconchd.exe %OUTDIR%\mediaconch-server.exe

rem *** copy deps *** 
copy buildenv01\LIBCURL.DLL %OUTDIR%
%BASH% "for d in $(ldd %OUTDIR%/mediaconch-server.exe | cut -d' ' -f3 | grep 'mingw32/bin') ; do test ! -e %OUTDIR%/$(basename $d) && cp $d %OUTDIR% ; done"

echo MediaConch Server is located at %OUTDIR%\mediaconch-server.exe

rem *** Cleaning ***
:clean
set PATH=%OLD_PATH%
cd %OLD_CD%