@ECHO off
CD /D "%~dp0"
SET mapname=%~1

:mapname
IF NOT DEFINED mapname SET /P mapname="Map Name: "
IF NOT DEFINED mapname GOTO mapname

@ECHO.
@ECHO %mapname%

if not exist "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%" (
	@ECHO Error: The map doesn't exist.
	PAUSE
	GOTO eof
)

IF NOT EXIST "%cd%\Mods\maps" md "%cd%\Mods\maps"
IF NOT EXIST "%cd%\Mods\maps\%mapname%" md "%cd%\Mods\maps\%mapname%"
COPY "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%\*.*" "%cd%\Mods\maps\%mapname%"

@ECHO Building Map Data...

REM tools\binaryAssetBuilder.exe "%cd%\Mods\maps\%mapname%\map.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:false /gui:false /UsePrecompiled:true /LinkedStreams:true
tools\binaryAssetBuilder.exe "%cd%\Mods\maps\%mapname%\map.xml" /od:"%cd%\BuiltMods" /iod:"%cd%\BuiltMods" /ls:true /pc:true /ss:true"

@ECHO Fixing Map Data....
tools\hashfix.exe "%cd%\BuiltMods\mods\maps\%mapname%\map.manifest"
COPY "%cd%\BuiltMods\CnC3Xml\worldbuilder.manifest" "%cd%\BuiltMods\mods\maps\%mapname%\worldbuilder.manifest" /Y
tools\AssetResolver.exe -m "%cd%\BuiltMods\mods\maps\%mapname%\map.manifest" -s "map"

COPY "%cd%\BuiltMods\mods\maps\%mapname%\map.manifest" "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"
COPY "%cd%\BuiltMods\mods\maps\%mapname%\map.bin" "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"
COPY "%cd%\BuiltMods\mods\maps\%mapname%\map.relo" "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"
COPY "%cd%\BuiltMods\mods\maps\%mapname%\map.imp" "%APPDATA%\Command & Conquer 3 Tiberium Wars\maps\%mapname%"

DEL "%cd%\Mods\maps\%mapname%\*.*" /Q
RD "%cd%\Mods\maps\%mapname%"
RD "%cd%\Mods\maps"

DEL "%cd%\BuiltMods\mods\maps\%mapname%\map\assets\*.*" /Q
RD "%cd%\BuiltMods\mods\maps\%mapname%\map\assets"
RD "%cd%\BuiltMods\mods\maps\%mapname%\map"
DEL "%cd%\BuiltMods\mods\maps\%mapname%\*.*" /Q
RD "%cd%\BuiltMods\mods\maps\%mapname%"
RD "%cd%\BuiltMods\mods\maps"

@ECHO Compilation Complete!

PAUSE
:eof