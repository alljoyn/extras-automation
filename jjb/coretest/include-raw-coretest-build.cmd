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

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /s

set PFXDIR="%CD%\core"

rd /s /q %PFXDIR%
mkdir %PFXDIR%
cd %PFXDIR%

for /l %PROJ in ( alljoyn ajtcl test ) do (
  mkdir %PROJ
  cd %PROJ

  git init
  git remote add origin https://git.allseenalliance.org/gerrit/core/%%PROJ.git

  COMMIT_ISH=%GERRIT_BRANCH%
  IF [%PROJ]==[%GERRIT_PROJECT%] (
    COMMIT_ISH=%GERRIT_PATCHSET_REVISION%
  )

  git fetch origin %COMMIT_ISH%
  git reset --hard FETCH_HEAD

  rem INFO git log
  git log -1
)

cd "%PFXDIR%\alljoyn"

@call :dt start scons %VARIANT% 3

cmd /c scons -j%NUMBER_OF_PROCESSORS% MSVC_VERSION=%MSVC_VERSION% V=1 OS=%AJ_OS% CPU=%AJ_CPU% BINDINGS=c,cpp,java WS=off DOCS=none BR=on VARIANT=%VARIANT%
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)
@call :dt end scons 3

cd ..\ajtcl

cmd /c scons -j%NUMBER_OF_PROCESSORS% MSVC_VERSION=%MSVC_VERSION% OS=%AJ_OS% CPU=%AJ_CPU% BINDINGS=c,cpp,java DOCS=html VARIANT=%VARIANT% WS=off
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)
cd ..\test\scl

cmd /c scons -j%NUMBER_OF_PROCESSORS% MSVC_VERSION=%MSVC_VERSION% OS=%AJ_OS% CPU=%AJ_CPU% DOCS=html VARIANT=%VARIANT% WS=off AJ_CORE_DIST_DIR=..\..\alljoyn\build\%AJ_OS%\%AJ_CPU%\%VARIANT%\dist
@IF %ERRORLEVEL% GTR 0 (ECHO =========SCONS FAILED========= & exit -1)
dir /s/l/b *.exe
ajtcsctest.exe

@call :end

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
