@ECHO off
setlocal EnableDelayedExpansion
SET SDK_DIR=%~dp0

:: Set parameters
SET "modname=%~1"
SET "modversion=%~2"

:modname
IF NOT DEFINED modname SET /P modname="Mod Name: "
IF NOT DEFINED modname GOTO :modname

IF NOT EXIST "%SDK_DIR%Mods\%modname%" (
	@ECHO Error: The mod "%modname%" doesn't exist. Try again.
	SET "modname="
	SET "modversion="
	GOTO :modname )

:modversion
IF NOT DEFINED modversion SET /P modversion="Mod Version: "
FOR /F "delims=0123456789." %%A IN ("%modversion%") DO SET modversion=
IF NOT DEFINED modversion (
	@ECHO Error: Mod version was either not defined or is not a number, please re-input.
	GOTO modversion )

@ECHO Building %modname% Mod Data...
IF EXIST "%SDK_DIR%Mods\%modname%\Data\Mod.xml" (
	tools\binaryAssetBuilder.exe "%SDK_DIR%Mods\%modname%\Data\Mod.xml" /od:"%SDK_DIR%BuiltMods" /iod:"%SDK_DIR%BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true )

IF EXIST "%SDK_DIR%Mods\%modname%\Data\AdditionalMaps\MapMetaData_Global.xml" (
	tools\binaryAssetBuilder.exe "%SDK_DIR%Mods\%modname%\Data\AdditionalMaps\MapMetaData_Global.xml" /od:"%SDK_DIR%BuiltMods" /iod:"%SDK_DIR%BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true )

IF EXIST "%SDK_DIR%Mods\%modname%\Data\APTUI" (
	for %%f in ("%SDK_DIR%Mods\%modname%\Data\APTUI\*.xml") do (
		tools\binaryAssetBuilder.exe "%%f" /od:"%SDK_DIR%BuiltMods" /iod:"%SDK_DIR%BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
	)
)

IF EXIST "%SDK_DIR%Mods\%modname%\Data\Worldbuilder.xml" (
	tools\binaryAssetBuilder.exe "%SDK_DIR%Mods\%modname%\Data\Worldbuilder.xml" /od:"%SDK_DIR%BuiltMods" /iod:"%SDK_DIR%BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true )

@ECHO Building Low LOD...
IF EXIST "%SDK_DIR%Mods\%modname%\Data\Mod.xml" (
	tools\binaryAssetBuilder.exe "%SDK_DIR%Mods\%modname%\Data\Mod.xml" /od:"%SDK_DIR%BuiltMods" /iod:"%SDK_DIR%BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true /bcn:LowLOD /bps:"%SDK_DIR%BuiltMods\mods\%modname%\data\Mod.manifest" )

IF EXIST "%SDK_DIR%Art\%modname%\Terrain" (
	@ECHO Copying Terrain files...
	IF NOT EXIST "%SDK_DIR%BuiltMods\Mods\%modname%\Art\Terrain" (
		MD "%SDK_DIR%BuiltMods\Mods\%modname%\Art\Terrain" )
	XCOPY "%SDK_DIR%Art\%modname%\Terrain" "%SDK_DIR%BuiltMods\Mods\%modname%\Art\Terrain" /e /y )

IF EXIST "%SDK_DIR%Mods\%modname%\MOD.str" (
	@ECHO Copying STR file...
	COPY "%SDK_DIR%Mods\%modname%\MOD.str" "%SDK_DIR%BuiltMods\Mods\%modname%\Data" )

IF EXIST "%SDK_DIR%Mods\%modname%\Shaders" (
	@ECHO Copying Shaders...
	IF NOT EXIST "%SDK_DIR%BuiltMods\Mods\%modname%\Shaders" (
		MD "%SDK_DIR%BuiltMods\Mods\%modname%\Shaders" )
	XCOPY "%SDK_DIR%Mods\%modname%\Shaders" "%SDK_DIR%BuiltMods\Mods\%modname%\Shaders" /e /y )

IF EXIST "%SDK_DIR%Mods\%modname%\Scripts" (
	@ECHO Copying LUA Scripts...
	IF NOT EXIST "%SDK_DIR%BuiltMods\Mods\%modname%\Scripts" (
		MD "%SDK_DIR%BuiltMods\Mods\%modname%\Data\Scripts" )
	XCOPY "%SDK_DIR%Mods\%modname%\Scripts" "%SDK_DIR%BuiltMods\Mods\%modname%\Data\Scripts" /e /y )

IF EXIST "%SDK_DIR%Mods\%modname%\INI" (
	@ECHO Copying INI...
	IF NOT EXIST "%SDK_DIR%BuiltMods\Mods\%modname%\INI" (
		MD "%SDK_DIR%BuiltMods\Mods\%modname%\Data\INI" )
	XCOPY "%SDK_DIR%Mods\%modname%\INI" "%SDK_DIR%BuiltMods\Mods\%modname%\Data\INI" /e /y )

IF EXIST "%SDK_DIR%Mods\%modname%\Data\maps" (
	@ECHO Copying Maps
	IF NOT EXIST "%SDK_DIR%BuiltMods\Mods\%modname%\Data\maps" (
		MD "%SDK_DIR%BuiltMods\Mods\%modname%\Data\maps" )
	XCOPY "%SDK_DIR%Mods\%modname%\Data\maps" "%SDK_DIR%BuiltMods\Mods\%modname%\Data\maps" /e /y )

@ECHO Creating Mod Big and Skudef file...
tools\MakeBig.exe -f "%SDK_DIR%BuiltMods\Mods\%modname%" -x:*.asset -o:"%SDK_DIR%BuiltMods\Mods\%modname%_%modversion%.big"

SET skudef_file=%SDK_DIR%BuiltMods\Mods\%modname%_%modversion%.skudef
ECHO mod-game 1.9> "%skudef_file%"
ECHO add-big %modname%_%modversion%.big>> "%skudef_file%"

SET modpath="C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods\%modname%"

@ECHO Copying %modname% Big and Skudef files to documents folder...
IF NOT EXIST %modpath% (
	MD %modpath% )
COPY "%SDK_DIR%BuiltMods\Mods\%modname%_%modversion%.big" %modpath% /y
COPY "%skudef_file%" %modpath% /y

@ECHO Compilation Complete!
@ECHO.

:choice
SET /P c=Do you want to compile again [Y/N]? 
IF /I "%c%" EQU "Y" (
	SET "modname="
	SET "modversion="
	GOTO :modname )

IF /I "%c%" EQU "N" GOTO :eof

@ECHO Invalid or blank choice. Please enter Y or N.
GOTO :choice

PAUSE
:eof

endlocal