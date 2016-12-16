@echo off

rem *** Init ***

rem save old path
set OLD_PATH=%PATH%
set OLD_CD=%CD%

rem make output dir
set OUTDIR=MediaConch-GUI
mkdir %OUTDIR%

rem set env
set MAKE=mingw32-make
set BASH=%CD%\buildenv01\usr\bin\bash --login -c
set MSYSTEM=MINGW32
set CXXFLAGS=-static -DNTDDI_VERSION=0x06000000 -D_WIN32_WINNT=0x0600

rem initialize bash user files (needed to make CHERE_INVOKING work)
%BASH% "exit"

set CHERE_INVOKING=1

rem rebase binaries
pushd buildenv01\mingw32\bin
	qtbinpatcher --nobackup
popd

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
for %%i in (MediaConch-Policy MediaConch-Implementation) do (
	rem *** Configure MediaConch GUI ***
	pushd mediaconch_AllInclusive\%%i\Project\Qt
		%OLD_CD%\buildenv01\mingw32\bin\qmake DEFINES+=NTDDI_VERSION=0x06000000 DEFINES+=_WIN32_WINNT=0x0600 USE_WEBKIT=1 STATIC_LIBS=1 INCLUDEPATH+=%OLD_CD%\msys32\mingw32\include\libxml2 INCLUDEPATH+=..\..\..\ZenLib/Source  INCLUDEPATH+=../../../MediaInfoLib/Source LIBS+="..\..\..\MediaInfoLib\Project\GNU\Library\.libs\libmediainfo.a ..\..\..\ZenLib\Project\GNU\Library\.libs\libzen.a -lole32 -luuid -levent -lsqlite3 -lexslt -lxslt -lxml2 -llzma -liconv -ljansson -llibcurl -lws2_32" -after LIBS-=-ldl LIBS-=-lrt
	popd
	if not exist mediaconch_AllInclusive\%%i\Project\Qt\Makefile (
		echo  ERROR: while MediaConch GUI configure
		goto :clean
	)

	rem *** Build MediaConch GUI ***
	pushd mediaconch_AllInclusive\%%i\Project\Qt
		%BASH% "%MAKE%"
	popd
	if not exist mediaconch_AllInclusive\%%i\Project\Qt\release\%%i-gui.exe (
		echo ERROR: while MediaConch GUI build
		goto :clean
	)
	copy mediaconch_AllInclusive\%%i\Project\Qt\release\%%i-gui.exe %OUTDIR%
)

rem *** copy deps *** 
copy buildenv01\LIBCURL.DLL %OUTDIR%
%BASH% "windeployqt %OUTDIR%/*.exe"
%BASH% "for bin in %OUTDIR%/*.exe ; do for d in $(ldd $bin | cut -d' ' -f3 | grep 'mingw32/bin') ; do test ! -e %OUTDIR%/$(basename $d) && cp $d %OUTDIR% ; done ; done"

echo MediaConch Implementation checker GUI is located at %OUTDIR%\mediaconch-implementation-gui.exe
echo MediaConch Policy checker GUI is located at %OUTDIR%\mediaconch-policy-gui.exe

rem *** Cleaning ***
:clean
set PATH=%OLD_PATH%
cd %OLD_CD%