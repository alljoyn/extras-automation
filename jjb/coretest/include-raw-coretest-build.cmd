prompt +

setlocal EnableDelayedExpansion

for /F "usebackq tokens=1,2 delims=.=" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set RUN_TS=%%j

echo "Test run started at %RUN_TS%"

set

REM BUILD DESCRIPTION : GERRIT_CHANGE_OWNER_EMAIL=%GERRIT_CHANGE_OWNER_EMAIL%, BUILD_USER_EMAIL=%BUILD_USER_EMAIL%, GERRIT_BRANCH=%GERRIT_BRANCH%, GIT_COMMIT=%GIT_COMMIT%
set PATH=%JAVA_HOME%\bin;c:\tools\;c:\tools\gnuwin32\bin;"C:\Program Files\Git\usr\bin";"c:\program files (x86)\windows kits\10\debuggers\x64";%PATH%

set ALLJOYN_CRASH_DUMP_SUPPORT=1
set DUMP_LOCATION=\j\c\workspace\proc.dmp

set BUS_ADDRESS=null:
set BUS_ADDRESS1=null:
set BUS_ADDRESS2=null:
set BUS_ADDRESS3=null:

set AJ_CPU=x86_64

set SQLITE_DIR=C:\tools\sqlite

set HOME=%WORKSPACE%\home
set TEMP=%WORKSPACE%\temp
set OUTDIRNAME=artifacts
set OUTDIR=%WORKSPACE%\%OUTDIRNAME%\
set PFXDIR=%WORKSPACE%\core

set "FAIL="

set

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /s

rd /s /q %PFXDIR%
mkdir %PFXDIR% %HOME% %TEMP% %OUTDIR%
cd %PFXDIR%

REM check out each project's code from git
REM * for the project which triggered this build, check out the specific refspec.
REM * for all others, check out the branch against which the refspec is based

FOR %%P IN (alljoyn,ajtcl,test) DO (
  IF ["core/%%P"]==["%GERRIT_PROJECT%"] ( set GREF=%GERRIT_REFSPEC% ) ELSE ( set GREF=%GERRIT_BRANCH% )

  mkdir "%PFXDIR%\%%P"
  cd "%PFXDIR%\%%P"

  echo Checking out ref !GREF!

  git init
  git remote add origin https://git.allseenalliance.org/gerrit/core/%%P.git
  git fetch -q origin !GREF! > NUL 2>&1
  git reset --hard FETCH_HEAD > NUL 2>&1

  rem INFO git log
  git log -1
)

IF [%AJ_OS%]==[win7] (
  set SCONS_OPTS=-j%NUMBER_OF_PROCESSORS% VARIANT=%VARIANT% WS=off
) ELSE (
  set SCONS_OPTS=-j%NUMBER_OF_PROCESSORS% MSVC_VERSION=%MSVC_VERSION% OS=%AJ_OS% CPU=%AJ_CPU% VARIANT=%VARIANT% WS=off
)

mkdir %PFXDIR%\alljoyn\build\%AJ_OS%\%AJ_CPU%\%VARIANT%\dist

set BUILD_OPTS[alljoyn]=DOCS=none BINDINGS=c,cpp,java V=1 BR=on
set BUILD_OPTS[ajtcl]=DOCS=html BINDINGS=c,cpp,java
set BUILD_OPTS[test-scl]=DOCS=html AJ_CORE_DIST_DIR=%PFXDIR%\alljoyn\build\%AJ_OS%\%AJ_CPU%\%VARIANT%\dist

echo "=== STARTING BUILDS ==="

FOR %%N IN (alljoyn,ajtcl,test-scl) DO (
  set N=%%N
  set D=!N:-=\!
  cd %PFXDIR%\!D!
  cd
  @call :dt start scons %VARIANT% 3
  set LOG_NAME=%%N-%RUN_TS%.log

  cmd /c scons %SCONS_OPTS% !BUILD_OPTS[%%N]! 2>&1 | tee %LOG_NAME%
  @IF %ERRORLEVEL% GTR 0 (
    ECHO =========SCONS FAILED=========
    REN %LOG_NAME% %%N-%RUN_TS%-fail.log
    set LOG_NAME=%%N-%RUN_TS%-fail.log
    SET FAIL=1
  )
  MOVE %LOG_NAME% %OUTDIR%
  @call :dt end scons 3
)

echo "=== BUILDS COMPLETE ==="

cd %WORKSPACE%
dir /s/l/b *.exe

echo "=== STARTING ALLJOYN TCSC UNIT TESTS ==="

cd "%PFXDIR%\test\scl"

set TEST_NAME=AJTCSCTEST
set LOG_NAME=%TEST_NAME%-%RUN_TS%.log

dir /s/l/b *.exe
ajtcsctest.exe 2>&1 | tee %LOG_NAME%
@call :errorcheck
MOVE %LOG_NAME% %OUTDIR%

echo "=== ALLJOYN TCSC UNIT TESTS COMPLETE ==="

echo "=== STARTING ALLJOYN BVT SUITE ==="

cd "%PFXDIR%\alljoyn"
cd

set TDIR[AJCHECK]=cpp
set TDIR[AJCTEST]=c
set TDIR[AJTEST]=cpp
set TDIR[CMTEST]=cpp
set TDIR[ABOUTTEST]=cpp
set TDIR[SECMGRTEST]=cpp

FOR %%T IN (AJCHECK,AJCTEST,AJTEST,CMTEST,ABOUTTEST,SECMGRTEST) DO (
  set TEST_DIR=%PFXDIR%\alljoyn\build\%AJ_OS%\%AJ_CPU%\%VARIANT%\test\!TDIR[%%T]!\bin

  set "DOTEST="
  IF [%%T]==[SECMGRTEST] IF EXIST !TEST_DIR!\%%T.exe set DOTEST=1
  IF NOT [%%T]==[SECMGRTEST] set DOTEST=1

  IF defined DOTEST call :runtest %%T !TEST_DIR!
)

echo "=== ALLJOYN BVT SUITE COMPLETE ==="

@call :end

:runtest
    SET TEST_NAME=%1
    SET TEST_DIR=%2

    del /F /Q %HOME%\*
    del /F /Q %TEMP%\*

    @echo START %TEST_NAME%
    @call :dt START %TEST_NAME%
    set LOG_NAME=%TEST_NAME%-%RUN_TS%.log
    cmd /c %TEST_DIR%\%TEST_NAME%.exe --gtest_catch_exceptions=0 2>&1 | tee %LOG_NAME%
    @call :errorcheck
    @call :dumpcheck %TEST_NAME% %TEST_DIR%
    findstr /c:"exiting with status 0" %LOG_NAME%
    @call :errorcheck
    @call :dt END %TEST_NAME%
exit /b


:dumpcheck
    sleep 1
    FOR /F "tokens=*" %%a IN ('tlist -p windbg') DO SET windbgPid=%%a

    IF %windbgPid% GTR -1 (
       sleep 30
       kill -f %windbgPid%
    )

    IF EXIST %DUMP_LOCATION% (
        SET TEST_NAME=%1
        SET TEST_DIR=%2

        move %DUMP_LOCATION% %OUTDIR%\%TEST_NAME%.dmp
        move %TEST_DIR%\%TEST_NAME%.pdb %TEST_DIR%\%TEST_NAME%.exe %OUTDIR%
        @echo captured dump for %TEST_NAME%.exe
    )
exit /b

:errorcheck
    @IF %ERRORLEVEL% GTR 0 (
        ECHO ** error: ERROR TEST FAILED **
        SET FAIL=1
        REN %LOG_NAME% %TEST_NAME%-%RUN_TS%-fail.log
        set LOG_NAME=%TEST_NAME%-%RUN_TS%-fail.log
    )
@exit /b

:dt
@for /F "usebackq tokens=1,2 delims==" %%i in (`@wmic os get LocalDateTime /VALUE 2^>NUL`) do @if '.%%i.'=='.LocalDateTime.' set ldt=%%j
@set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%,%ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
@if "" == "%4" (
@echo %ldt%,%1,%2,%3 >>______timings.csv.log
) ELSE (
@echo %ldt%,%1,%2,%3,%4 >>______timings.csv.log
)
@exit /b

:end
pwd
move *.log %OUTDIR%\
dir /s/l/b *.log
@systeminfo > %OUTDIR%\systeminfo.log

cd %WORKSPACE%
pwd

dir /s/l/b %OUTDIRNAME%

@IF defined FAIL (ECHO FAIL FAIL FAIL & exit -1)

@exit
