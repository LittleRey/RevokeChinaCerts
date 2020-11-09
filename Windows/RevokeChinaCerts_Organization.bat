:: RevokeChinaCerts Organization batch
:: Revoke China Certificates.
:: 
:: Author: Hugo Chan, ntkme, Chengr28
:: 


@echo off


:: Check administrative permission.
net session >NUL 2>NUL
if ERRORLEVEL 1 (
	color 4F
	echo Please run as Administrator.
	echo.
	pause & break
	echo.
	cls
)


:: Locate folder and architecture check.
cd /D "%~dp0"
set CertMgr="%~dp0Tools\CertMgr.exe"
if %PROCESSOR_ARCHITECTURE%%PROCESSOR_ARCHITEW6432% EQU x86 (
	set CertMgr="%~dp0Tools\CertMgr_x86.exe"
)
set Certificates="%~dp0Certificates\Organization
set /A ForcePolicy = 0
set SetForceAppender="%~dp0Tools\SoftCertPolicyAppender\Binary\SoftCertPolicyAppender.exe"


:: Command
set CommandType=%~1
set CommandPolicy=%~2
if "%CommandPolicy%" == "-f" (
	set /A ForcePolicy=1
)
if not "%CommandType%" == "" (
	goto CASE_%CommandType%
)


:: Choice
echo RevokeChinaCerts Organization batch
echo.
echo Do you want to set force certificate policy? [Y/N]
echo Setting force require:
echo   Administrative Privileges
echo   Microsoft .NET Framework 4.0 or later version
set /P UserChoice="Choose: "
if /I %UserChoice% EQU Y (
	set /A ForcePolicy=1
)
echo.
echo 1: Revoke all Organization certificates
echo 2: Restore all Organization revoking
echo Notice: Choice version is no longer available. Please remove the certificate fingerprint(s) in 
echo         /Windows/Certificates/CodeSigning/CodeSigning.txt or 
echo         /Windows/Certificates/Organization/Organization.txt to 
echo         make it/them not to be revoked.
echo.
set /P UserChoice="Choose: "
set UserChoice=CASE_%UserChoice%
cls
goto %UserChoice%


:: Support functions
:REVOKE_SYSTEM
%CertMgr% -add -c %Certificates%\%~1.crt" -s -r localMachine Disallowed
%CertMgr% -add -c %Certificates%\%~1.crt" -s -r currentUser Disallowed
goto :EOF

:REVOKE_POLICY
if "%CommandType%" == "" (
	%SetForceAppender% --set-force --interval 1000 %Certificates%\%~1.crt"
) else (
	%SetForceAppender% --set-force --quiet --interval 1000 %Certificates%\%~1.crt"
)
goto :EOF

:RESTORE_SYSTEM
%CertMgr% -del -c -sha1 %~1 -s -r localMachine Disallowed
%CertMgr% -del -c -sha1 %~1 -s -r currentUser Disallowed
goto :EOF

:RESTORE_POLICY
if "%CommandType%" == "" (
	%SetForceAppender% --remove --unset-force --interval 1000 %Certificates%\%~1.crt"
) else (
	%SetForceAppender% --remove --unset-force --quiet --interval 1000 %Certificates%\%~1.crt"
)
goto :EOF


:: All version
:CASE_1
if %ForcePolicy% EQU 0 (
	for /F "usebackq tokens=*" %%i in (%Certificates%\Organization.txt") do call :REVOKE_SYSTEM "%%i"
) else (
	for /F "usebackq tokens=*" %%i in (%Certificates%\Organization.txt") do call :REVOKE_POLICY "%%i"
)
goto EXIT


:: Restore version
:CASE_2
if %ForcePolicy% EQU 1 (
	for /F "usebackq tokens=*" %%i in (%Certificates%\Organization.txt") do call :RESTORE_POLICY "%%i"
)
for /F "usebackq tokens=*" %%i in (%Certificates%\Organization.txt") do call :RESTORE_SYSTEM "%%i"
goto EXIT


:: Exit
:EXIT
color
cd /D "%~dp0"
echo.
echo RevokeChinaCerts Organization batch
echo Done, please confirm the messages on screen.
echo.
pause
cls
