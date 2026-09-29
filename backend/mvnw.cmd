@REM ----------------------------------------------------------------------------
@REM Maven Start Up Batch script
@REM ----------------------------------------------------------------------------

@if "%DEBUG%" == "" @echo off

@setlocal

set MAVEN_CMD_LINE_ARGS=%*

if exist "C:\tools\apache-maven-3.9.6\bin\mvn.cmd" (
    call "C:\tools\apache-maven-3.9.6\bin\mvn.cmd" %MAVEN_CMD_LINE_ARGS%
) else (
    mvn %MAVEN_CMD_LINE_ARGS%
)
