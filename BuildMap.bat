@ECHO off
SETLOCAL EnableExtensions DisableDelayedExpansion

FOR %%i IN ("%~f0") DO SET "SDK_DIR=%%~dpi"

:: Set parameters
SET "mapname=%~1"
SET "MAP_VERSION_SUFFIX=%~2"

:compile_start

IF NOT DEFINED mapname (
	SET /P "mapname=Enter Map Name: "
)

IF NOT DEFINED mapname (
	ECHO Error: Map name cannot be empty.
	SET "mapname="
	GOTO :compile_start
)

SET "MAP_FOLDER=%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"

IF NOT EXIST "%MAP_FOLDER%" (
	ECHO Error: The map folder "%MAP_FOLDER%" doesn't exist.
	SET "mapname="
	GOTO :compile_start
)

IF NOT DEFINED MAP_VERSION_SUFFIX (
	SET /P "MAP_VERSION_SUFFIX=Enter Map Version Suffix or leave blank for no Suffix: "
)

IF DEFINED MAP_VERSION_SUFFIX (
	IF NOT "%MAP_VERSION_SUFFIX:~0,1%"=="_" (
		SET "MAP_VERSION_SUFFIX=_%MAP_VERSION_SUFFIX%"
	)
)

SETLOCAL EnableDelayedExpansion

:: Set file paths
SET "MAP_FOLDER_IN_MODS=!SDK_DIR!Mods\maps\!mapname!"
SET "BUILTMOD_FOLDER=!SDK_DIR!BuiltMods\Mods\maps\!mapname!"
SET "WB_MANIFEST_PATH=!SDK_DIR!BuiltMods\CnC3Xml"

SET "MAP_OUTPUT_NAME=map"

IF DEFINED MAP_VERSION_SUFFIX (
	SET "MAP_OUTPUT_NAME=map!MAP_VERSION_SUFFIX!"
)

IF NOT EXIST "!MAP_FOLDER_IN_MODS!" (
	MD "!MAP_FOLDER_IN_MODS!"
)

ECHO.
ECHO --- Compiling Map Data for "!mapname!" ---

XCOPY /E /Y "!MAP_FOLDER!" "!MAP_FOLDER_IN_MODS!"

:: Build map.xml
IF EXIST "!MAP_FOLDER_IN_MODS!\map.xml" (
	ECHO.
	ECHO --- Compiling map.xml...
	tools\binaryAssetBuilder.exe "!MAP_FOLDER_IN_MODS!\map.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /pc:true /ss:true
)

ECHO.
ECHO --- Fixing Map Data...

IF EXIST "!BUILTMOD_FOLDER!\map.manifest" (
	tools\hashfix.exe "!BUILTMOD_FOLDER!\map.manifest"
	COPY /Y "!WB_MANIFEST_PATH!\worldbuilder.manifest" "!BUILTMOD_FOLDER!\worldbuilder.manifest"

	ECHO.
	tools\AssetResolver.exe -m "!BUILTMOD_FOLDER!\map.manifest" -s "map"
)

COPY /Y "!BUILTMOD_FOLDER!\map.manifest" "!MAP_FOLDER!\!MAP_OUTPUT_NAME!.manifest"
COPY /Y "!BUILTMOD_FOLDER!\map.bin" "!MAP_FOLDER!\!MAP_OUTPUT_NAME!.bin"
COPY /Y "!BUILTMOD_FOLDER!\map.relo" "!MAP_FOLDER!\!MAP_OUTPUT_NAME!.relo"
COPY /Y "!BUILTMOD_FOLDER!\map.imp" "!MAP_FOLDER!\!MAP_OUTPUT_NAME!.imp"

IF DEFINED MAP_VERSION_SUFFIX (
	> "!MAP_FOLDER!\map.version" ECHO(!MAP_VERSION_SUFFIX!
) ELSE (
	IF EXIST "!MAP_FOLDER!\map.version" DEL /Q "!MAP_FOLDER!\map.version"
)

IF EXIST "!SDK_DIR!Mods\maps" (
	RMDIR /S /Q "!SDK_DIR!Mods\maps"
)

IF EXIST "!SDK_DIR!BuiltMods\mods\maps" (
	RMDIR /S /Q "!SDK_DIR!BuiltMods\mods\maps"
)

ENDLOCAL

ECHO.
ECHO =================================
ECHO       Compilation Complete!
ECHO =================================
ECHO.

:choice
SET "ANS="
SET /P "ANS=Do you want to compile again? [Y/N]: "

IF /I "%ANS%"=="Y" (
	SET "mapname="
	SET "MAP_VERSION_SUFFIX="
	GOTO :compile_start
)

IF /I "%ANS%"=="N" GOTO :EOF

IF "%ANS%"=="" (
	ECHO Answer is blank. Please enter Y or N.
) ELSE (
	ECHO Answer is invalid. Please enter Y or N.
)

GOTO :choice