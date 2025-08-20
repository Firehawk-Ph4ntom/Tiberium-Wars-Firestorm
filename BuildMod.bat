@ECHO off
SETLOCAL EnableExtensions DisableDelayedExpansion

SET "FULL_PATH=%~f0"
FOR %%i IN ("%FULL_PATH%") DO SET "SDK_DIR=%%~dpi"

:: Set parameters
SET "modname=%~1"
SET "modversion=%~2"

:get_modname
IF NOT DEFINED modname (
	SET /P "modname=Enter Mod Name: "
)

IF NOT DEFINED modname (
	@ECHO Error: Mod name cannot be empty. Please try again.
	GOTO :get_modname
)

IF NOT EXIST "%SDK_DIR%Mods\%modname%" (
	@ECHO Error: The mod folder "%SDK_DIR%Mods\%modname%" doesn't exist. Please re-input.
	SET "modname="
	SET "modversion="
	GOTO :get_modname
)

SETLOCAL EnableDelayedExpansion

SET /A "modname_len=0"
FOR /L %%i IN (0,1,255) DO IF NOT "!modname:~%%i,1!"=="" SET /A "modname_len+=1"

IF !modname_len! GTR 15 (
	@ECHO Error: Mod name length exceeds 15 characters. Please re-input.
	ENDLOCAL
	SET "modname="
	SET "modversion="
	GOTO :get_modname
)

:get_modversion
IF NOT DEFINED modversion (
	SET /P "modversion=Enter Mod Version: "
)

IF "!modversion!"=="" (
	@ECHO Error: Mod version cannot be empty. Please re-input.
	GOTO :get_modversion
)

SET /A "modversion_len=0"
FOR /L %%i IN (0,1,255) DO IF NOT "!modversion:~%%i,1!"=="" SET /A "modversion_len+=1"

IF !modversion_len! GTR 5 (
	@ECHO Error: Mod version length exceeds 5 characters. Please re-input.
	SET "modversion="
	GOTO :get_modversion
)

:: Set file paths
SET "MOD_PATH=!SDK_DIR!Mods\!modname!"
SET "BUILTMOD_PATH=!SDK_DIR!BuiltMods\Mods\!modname!"
SET "SKUDEF_FILE=!BUILTMOD_PATH!_!modversion!.skudef"
SET "DOC_PATH=%USERPROFILE%\Documents\Command & Conquer 3 Tiberium Wars\Mods\!modname!"

@ECHO.
@ECHO --- Building Mod Data for !modname!_!modversion! ---

:: Build Mod.xml
IF EXIST "!MOD_PATH!\Data\Mod.xml" (
	@ECHO.
	@ECHO --- Compiling Mod.xml...
	tools\binaryAssetBuilder.exe "!MOD_PATH!\Data\Mod.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
)

:: Build MapMetaData_Global.xml
IF EXIST "!MOD_PATH!\Data\AdditionalMaps\MapMetaData_Global.xml" (
	@ECHO.
	@ECHO --- Compiling MapMetaData_Global.xml...
	tools\binaryAssetBuilder.exe "!MOD_PATH!\Data\AdditionalMaps\MapMetaData_Global.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
)

:: Build APTUI XMLs
IF EXIST "!MOD_PATH!\Data\APTUI" (
	@ECHO.
	@ECHO --- Compiling APTUI XML files...
	FOR %%f IN ("!MOD_PATH!\Data\APTUI\*.xml") DO (
		@ECHO.
		@ECHO --- Compiling %%~nxf...
		tools\binaryAssetBuilder.exe "%%f" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
	)
)

:: Build for Low LOD
IF EXIST "!MOD_PATH!\Data\Mod.xml" (
	@ECHO.
	@ECHO --- Building Low LOD Assets...
	tools\binaryAssetBuilder.exe "!MOD_PATH!\Data\Mod.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true /bcn:LowLOD /bps:"!BUILTMOD_PATH!\data\Mod.manifest"
)

:: Build Worldbuilder.xml
IF EXIST "!MOD_PATH!\Data\Worldbuilder.xml" (
	@ECHO.
	@ECHO --- Compiling Worldbuilder.xml...
	tools\binaryAssetBuilder.exe "!MOD_PATH!\Data\Worldbuilder.xml" /od:"!SDK_DIR!BuiltMods" /iod:"!SDK_DIR!BuiltMods" /ls:true /gui:false /UsePrecompiled:true /vf:true
)

@ECHO.
@ECHO --- Copying Additional Mod Files ---

:: Copy Terrain files
IF EXIST "!SDK_DIR!Art\!modname!\Terrain" (
	@ECHO.
	@ECHO Copying Terrain files...
	CALL :CopyDir "!SDK_DIR!Art\!modname!\Terrain" "!BUILTMOD_PATH!\Art\Terrain"
)

:: Copy MOD.str file
IF EXIST "!MOD_PATH!\MOD.str" (
	@ECHO.
	@ECHO Copying STR file...
	CALL :CopyDir "!MOD_PATH!\MOD.str" "!BUILTMOD_PATH!\Data"
)

:: Copy Shaders
IF EXIST "!MOD_PATH!\Shaders" (
	@ECHO.
	@ECHO Copying Shaders...
	CALL :CopyDir "!MOD_PATH!\Shaders" "!BUILTMOD_PATH!\Shaders"
)

:: Copy LUA Scripts
IF EXIST "!MOD_PATH!\Scripts" (
	@ECHO.
	@ECHO Copying LUA Scripts...
	CALL :CopyDir "!MOD_PATH!\Scripts" "!BUILTMOD_PATH!\Data\Scripts"
)

:: Copy INI files
IF EXIST "!MOD_PATH!\INI" (
	@ECHO.
	@ECHO Copying INI files...
	CALL :CopyDir "!MOD_PATH!\INI" "!BUILTMOD_PATH!\Data\INI"
)

:: Copy Maps
IF EXIST "!MOD_PATH!\Data\maps" (
	@ECHO.
	@ECHO Copying Maps...
	CALL :CopyDir "!MOD_PATH!\Data\maps" "!BUILTMOD_PATH!\Data\maps"
)

:: Copy Movies
IF EXIST "!MOD_PATH!\Data\movies" (
	@ECHO.
	@ECHO Copying Movies...
	CALL :CopyDir "!MOD_PATH!\Data\movies" "!BUILTMOD_PATH!\Data\movies"
)

@ECHO.
ECHO Creating '!modname!_!modversion!.big' file...
tools\MakeBig.exe -f "!BUILTMOD_PATH!" -x:*.asset -o:"!BUILTMOD_PATH!_!modversion!.big"

@ECHO Creating '!modname!_!modversion!.skudef' file...
ECHO mod-game 1.9> "!SKUDEF_FILE!"
ECHO add-big !modname!_!modversion!.big>> "!SKUDEF_FILE!"

@ECHO.
@ECHO Copying '!modname!_!modversion!.big' and '!modname!_!modversion!.Skudef' files to Documents folder...

IF NOT EXIST "!DOC_PATH!" (
	MD "!DOC_PATH!"
)

COPY "!BUILTMOD_PATH!_!modversion!.big" "!DOC_PATH!" /Y
COPY "!SKUDEF_FILE!" "!DOC_PATH!" /Y

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
	SET "modname="
	SET "modversion="
	GOTO :get_modname
)

IF /I "%ANS%" EQU "N" GOTO :EOF

IF "%ANS%"=="" (
	@ECHO Answer is blank. Please enter Y or N.
) ELSE (
	@ECHO Answer is invalid. Please enter Y or N.
)
GOTO :choice

:: Global function to copy the additional Mod files
:CopyDir
IF EXIST "%~1" (
	IF NOT EXIST "%~2" MD "%~2"
	XCOPY "%~1" "%~2\" /E /Y
)
EXIT /B

PAUSE
ENDLOCAL