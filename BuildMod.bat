@ECHO off
CD /D "%~dp0"
SET modname=%~1

:modname
IF NOT DEFINED modname SET /P modname="Mod Name: "
IF NOT DEFINED modname GOTO modname

@ECHO.
@ECHO %modname%

if not exist "%cd%\Mods\%modname%" (
	@ECHO Error: The mod doesn't exist.
	PAUSE
	GOTO eof
)

@ECHO Building Mod Data...
	tools\binaryAssetBuilder.exe "%cd%\Mods\%modname%\Data\Mod.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
	tools\binaryAssetBuilder.exe "%cd%\Mods\%modname%\Data\AdditionalMaps\MapMetaData_Global.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
	tools\binaryAssetBuilder.exe "%cd%\Mods\%modname%\Data\APTUI\MainMenu.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
	tools\binaryAssetBuilder.exe "%cd%\Mods\%modname%\Data\APTUI\LoadScreen.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true

@ECHO Building Low LOD...
	tools\binaryAssetBuilder.exe "%cd%\Mods\%modname%\Data\Mod.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true /bcn:LowLOD /bps:"%cd%\BuiltMods\mods\%modname%\data\Mod.manifest"

@ECHO Copying Terrain files...
	IF NOT EXIST "%cd%\BuiltMods\Mods\%modname%\Art\Terrain" MD "%cd%\BuiltMods\Mods\%modname%\Art\Terrain"
		COPY "%cd%\Art\Firestorm\Terrain\*.tga" "%cd%\BuiltMods\Mods\%modname%\Art\Terrain"

@ECHO Copying STR file if it exists...
	IF EXIST "%cd%\Mods\%modname%\MOD.str" COPY "%cd%\Mods\%modname%\MOD.str" "%cd%\BuiltMods\Mods\%modname%\Data"

@ECHO Copying Shaders...
	IF NOT EXIST "%cd%\BuiltMods\Mods\%modname%\Shaders" MD "%cd%\BuiltMods\Mods\%modname%\Shaders"
		COPY "%cd%\Mods\%modname%\Shaders\*.fx" "%cd%\BuiltMods\Mods\%modname%\Shaders"

@ECHO Copying LUA Scripts...
	IF NOT EXIST "%cd%\BuiltMods\Mods\%modname%\Data\Scripts" MD "%cd%\BuiltMods\Mods\%modname%\Data\Scripts"
		XCOPY /s /i "%cd%\Mods\%modname%\Scripts" "%cd%\BuiltMods\Mods\%modname%\Data\Scripts"

@ECHO Copying INI...
	IF NOT EXIST "%cd%\BuiltMods\Mods\%modname%\Data\INI" MD "%cd%\BuiltMods\Mods\%modname%\Data\INI"
		COPY "%cd%\Mods\%modname%\INI\*.ini" "%cd%\BuiltMods\Mods\%modname%\Data\INI"
		DEL "%cd%\BuiltMods\Mods\%modname%\Data\Mod_L.version"

@ECHO Copying Maps
	IF NOT EXIST "%cd%\BuiltMods\Mods\%modname%\Data\maps" MD "%cd%\BuiltMods\Mods\%modname%\Data\maps"
		XCOPY /s /i "%cd%\Mods\%modname%\Data\maps" "%cd%\BuiltMods\Mods\%modname%\Data\maps"

@ECHO Creating Mod Big File...
	tools\MakeBig.exe -f "%cd%\BuiltMods\Mods\%modname%" -x:*.asset -o:"%cd%\BuiltMods\Mods\%modname%.big"

@ECHO Copying built mod...
	IF NOT EXIST "C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods" MD "C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods"
	IF NOT EXIST "C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods\%modname%" MD "C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods\%modname%"

COPY "BuiltMods\Mods\%modname%.big" "C:\Users\%username%\Documents\Command & Conquer 3 Tiberium Wars\Mods\%modname%"

@ECHO Compilation Complete!

PAUSE
:eof