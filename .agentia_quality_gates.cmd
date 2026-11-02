@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Local Agentia quality gates (Windows).
REM Agentia runs this from the repo root during `agentia cicd work test` (local by default)
REM and `agentia cicd work submit` (unless --skip-local-tests). Exit non-zero to stop the submit;
REM the output is uploaded to the user story as the local commit log.

echo ## Agentia Preflight ^& Triage
call agentia preflight run
if errorlevel 1 exit /b %errorlevel%

REM Stock Agentia checks. They need the code-analyzer plugin, Apex test classes and
REM node_modules, so they run only when AGENTIA_FULL_GATES=1.
if not "%AGENTIA_FULL_GATES%"=="1" exit /b 0

echo ## Running Code Analyzer
call sf code-analyzer run
if errorlevel 1 exit /b %errorlevel%

call agentia cicd work test apex -t "!AGENTIA_APEX_TEST_CLASSES!" !AGENTIA_APEX_RERUN_FAILED!
if errorlevel 1 exit /b %errorlevel%

echo ## Running LWC tests
call npx sfdx-lwc-jest -- --passWithNoTests
if errorlevel 1 exit /b %errorlevel%
