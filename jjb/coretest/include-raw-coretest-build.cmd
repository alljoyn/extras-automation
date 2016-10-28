prompt +

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

set

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /s

set PFXDIR="%CD%\core"

rd /s /q %PFXDIR%
mkdir %PFXDIR%
cd %PFXDIR%
echo %CD%

FOR %%P IN (alljoyn,ajtcl,test) DO (
  mkdir "%PFXDIR%\%%P"
  cd "%PFXDIR%\%%P"

  git init
  git remote add origin https://git.allseenalliance.org/gerrit/core/%%P.git

  IF ["core/%%P"]==["%GERRIT_PROJECT%"] (
    git fetch -q origin "%GERRIT_REFSPEC%"
  ) ELSE (
    git fetch -q origin "%GERRIT_BRANCH%"
  )

  git reset --hard FETCH_HEAD

  rem INFO git log
  git log -1
)

cd "%PFXDIR%\alljoyn"

set SCONS_OPTS="-j%NUMBER_OF_PROCESSORS% MSVC_VERSION=%MSVC_VERSION% OS=%AJ_OS% CPU=%AJ_CPU% VARIANT=%VARIANT% WS=off"

@call :dt start scons %VARIANT% 3

cmd /c scons %SCONS_OPTS% DOCS=none BINDINGS=c,cpp,java V=1 BR=on
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)
@call :dt end scons 3

cd "%PFXDIR%\ajtcl"

cmd /c scons %SCONS_OPTS% DOCS=html BINDINGS=c,cpp,java
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)

cd "%PFXDIR%\test\scl"

cmd /c scons %SCONS_OPTS% DOCS=html AJ_CORE_DIST_DIR=%PFXDIR%\alljoyn\build\%AJ_OS%\%AJ_CPU%\%VARIANT%\dist
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)

dir /s/l/b *.exe
ajtcsctest.exe

@call :end

:runtest
    SET TEST_NAME=%1
    SET TEST_DIR=%2

    del /F /Q %HOME%\*
    del /F /Q %TEMP%\*

    @echo START %TEST_NAME%
    @call :dt START %TEST_NAME%
    cmd /c %TEST_DIR%\%TEST_NAME%.exe --gtest_catch_exceptions=0 2>;1 | tee %TEST_NAME%.log
    @call :errorcheck
    @call :dumpcheck %TEST_NAME% %TEST_DIR%
    findstr /c:"exiting with status 0" %TEST_NAME%.log
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

        move %DUMP_LOCATION% artifacts\%TEST_NAME%.dmp
        move %TEST_DIR%\%TEST_NAME%.pdb artifacts\%TEST_NAME%.pdb
        move %TEST_DIR%\%TEST_NAME%.exe artifacts\%TEST_NAME%.exe
        @echo captured dump for %TEST_NAME%.exe
    )
exit /b

:errorcheck
    @IF %ERRORLEVEL% GTR 0 (
        ECHO ** error: ERROR TEST FAILED **
        SET FAIL=1
        REN %TEST_NAME%.log %TEST_NAME%-fail.log
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
@IF defined FAIL (ECHO FAIL FAIL FAIL & exit -1)

@exit
