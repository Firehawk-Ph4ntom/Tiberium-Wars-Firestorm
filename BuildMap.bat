@ECHO off
SETLOCAL EnableExtensions DisableDelayedExpansion

SET "FULL_PATH=%~f0"
FOR %%i IN ("%FULL_PATH%") DO SET "SDK_DIR=%%~dpi"

:: Set parameters
SET "mapname=%~1"

:get_mapname
IF NOT DEFINED mapname (
	SET /P "mapname=Enter Map Name: "
)

IF NOT DEFINED mapname (
	@ECHO Error: Map name cannot be empty.
	GOTO :get_mapname
)

SET "MAP_FOLDER=%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"
IF NOT EXIST "%MAP_FOLDER%" (
	@ECHO Error: The map folder "%MAP_FOLDER%" doesn't exist.
	SET "mapname="
	GOTO :get_mapname
)

SETLOCAL EnableDelayedExpansion

:: Set paths
SET "MAP_FOLDER_IN_MODS=!SDK_DIR!Mods\maps\!mapname!"
SET "BUILTMOD_FOLDER=!SDK_DIR!BuiltMods\Mods\maps\!mapname!"
SET "WB_MANIFEST_PATH=!SDK_DIR!BuiltMods\CnC3Xml"

:: Copy the map files over
IF NOT EXIST "!MAP_FOLDER_IN_MODS!" (
	MD "!MAP_FOLDER_IN_MODS!"
)

@ECHO.
@ECHO --- Compiling Map Data for "!mapname!" ---

XCOPY /e /y "!MAP_FOLDER!" "!MAP_FOLDER_IN_MODS!"

IF EXIST "!MAP_FOLDER_IN_MODS!\map.xml" (
	@ECHO.
	@ECHO --- Compiling map.xml...
	tools\binaryAssetBuilder.exe "!MAP_FOLDER_IN_MODS!\map.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /pc:true /ss:true
)

@ECHO.
@ECHO --- Fixing Map Data...

IF EXIST "!BUILTMOD_FOLDER!\map.manifest" (
	tools\hashfix.exe "!BUILTMOD_FOLDER!\map.manifest"
	COPY /Y "!WB_MANIFEST_PATH!\worldbuilder.manifest" "!BUILTMOD_FOLDER!\worldbuilder.manifest"

	@ECHO.
	tools\AssetResolver.exe -m "!BUILTMOD_FOLDER!\map.manifest" -s "map"
)

IF NOT EXIST "!MAP_FOLDER!" (
	MD "!MAP_FOLDER!"
)

COPY /Y "!BUILTMOD_FOLDER!\map.manifest" "!MAP_FOLDER!"
COPY /Y "!BUILTMOD_FOLDER!\map.bin" "!MAP_FOLDER!"
COPY /Y "!BUILTMOD_FOLDER!\map.relo" "!MAP_FOLDER!"
COPY /Y "!BUILTMOD_FOLDER!\map.imp" "!MAP_FOLDER!"


:: Delete the map folders in builtmods and in the normal mods folder
IF EXIST "!SDK_DIR!Mods\maps" (
	RMDIR /S /Q "!SDK_DIR!Mods\maps"
)

IF EXIST "!SDK_DIR!BuiltMods\mods\maps" (
	RMDIR /S /Q "!SDK_DIR!BuiltMods\mods\maps"
)

ENDLOCAL

@ECHO.
@ECHO =================================
@ECHO       Compilation Complete!
@ECHO =================================
@ECHO.

:choice
SET "ANS="
SET /P ANS=Do you want to compile again? [Y/N]: 

IF /I "%ANS%" EQU "Y" (
	SET "mapname="
	GOTO :get_mapname
)

IF /I "%ANS%" EQU "N" GOTO :EOF

IF "%ANS%"=="" (
	@ECHO Answer is blank. Please enter Y or N.
) ELSE (
	@ECHO Answer is invalid. Please enter Y or N.
)
GOTO :choice

PAUSE
ENDLOCAL