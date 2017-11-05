::\(.*\)/@optipng -o7 -strip all -out "\1" "\1"
::for /f "usebackq tokens=* delims=" %a in (`dir/b/ad "*201709" 2>nul`) do (dir/b/s/a-d "%~a\*.png">>optimizelist.lst)
::for /f "usebackq tokens=* delims=" %a in (`dir/b/ad "*201710" 2>nul`) do (dir/b/s/a-d "%~a\*.png">>optimizelist.lst)
:: -----------------------------------------------------------------------------
@echo off
chcp 65001 >nul 2>nul
setlocal enabledelayedexpansion

set "timepause=10"
set "cmmndsreexecuted=" :: commands failed multiple times
set "cmmndLast=-1"

:soc

set "listSF=%~sdpn0.lst"
set "annoSignSucc=::"
set "annoSignFail=rem "
set "cmmnd="

:: -- Get unexecuted command.
for /f "usebackq tokens=* delims=" %%a in ("%listSF%") do (
    if "!cmmnd!" == "" (
        if not "%%~a" == "" (
            set "line=%%~a"
            if not "!line:~0,2!" == "%annoSignSucc%" (
                if not "!line:~0,4!" == "%annoSignFail%" (
                    set "cmmnd=!line!"
                )
            )
        )
    )
)

:: -- When no unexecuted command exists, try to get the top failed command to re-execute
if "!cmmnd!" == "" (
    for /f "usebackq tokens=* delims=" %%a in ("%listSF%") do (
        if "!cmmnd!" == "" (
            if not "%%~a" == "" (
                set "line=%%~a"
                if "!line:~0,4!" == "%annoSignFail%" (

                    set "cmmnd=!line:~4!"
                    set "skip=0"

                    :: here
                    for /f "usebackq delims=////" %%b in ('!cmmndsreexecuted!') do (
                        if !skip! equ 0 if "%%~b" == "!cmmnd!" set "skip=1"
                    )
                    for /f "delims=////" %%b in ("!cmmndsreexecuted!") do (
                        if !skip! equ 0 if "%%~b" == "!cmmnd!" set "skip=1"
                    )

                    if !skip! equ 1 (
                        set "cmmnd="
                    ) else (
                        if "!cmmndsreexecuted!" == "" (
                            set "cmmndsreexecuted=!cmmnd!"
                        ) else (
                            set "cmmndsreexecuted=!cmmndsreexecuted!////!cmmnd!"
                        )
                    )
                )
            )
        )
    )
)

:: -- No command to be executed, queue over
if "!cmmnd!" == "" (
    set "cmmndsreexecuted="

    if !timepause! gtr 0 if not "!cmmndLast!" == "" ((
        if !timepause! leq 1 set "unitname=second" else set "unitname=seconds"
        echo/
        echo/:: -- ==============================
        ::echo/Empty queue, will check again in !timepause! !unitname!...
        echo/Empty queue, waiting for new item^(s^)...
        call :delay !timepause!000
    ))
)

:: -- Execute command and mark result
if not "!cmmnd!" == "" (
    echo/
    echo/:: -- ==============================
    echo/!cmmnd!
    if /i "!cmmnd:~0,8!" == "robocopy" (
        call !cmmnd!
        set "errlvl=!errorlevel!"

        if !errlvl! geq 8 (
            call :annotateExecutedLine %listSF%////%annoSignSucc%////!cmmnd!
        ) else (
            call :annotateExecutedLine %listSF%////%annoSignFail%////!cmmnd!
        )
    ) else (
        call !cmmnd!
        set "errlvl=!errorlevel!"

        if !errlvl! equ 0 (
            call :annotateExecutedLine %listSF%////%annoSignSucc%////!cmmnd!
        ) else (
            call :annotateExecutedLine %listSF%////%annoSignFail%////!cmmnd!
        )
    )
)

set "cmmndLast=!cmmnd!"

goto :soc

endlocal
exit/b
:: -----------------------------------------------------------------------------
:annotateExecutedLine   -- Mark executed command line in file as commented
::                      -- README
setlocal enabledelayedexpansion

set "listOri="
set "annoSign="
set "annoSignFail=rem "
set "cmdline="
set "cmdlinetemp="

:: here
for /f "usebackq tokens=1,2,* delims=////" %%a in ('%*') do (
    set "listOri=%%~a"
    set "annoSign=%%~b"
    set "cmdline=%%~c"
)
for /f "tokens=1,2,* delims=////" %%a in ("%*") do (
    set "cmdlinetemp=%%~c"
)
if not "!cmdline!" == "!temp!" (
    for /f "usebackq" %%a in (`echo/"%cmdline%" ^| find /c /i "="`) do (set "count0=%%~a")
    for /f "usebackq" %%a in (`echo/"%cmdlinetemp%" ^| find /c /i "="`) do (set "count1=%%~a")
    if !count0! lss !count1! set "cmdline=%cmdlinetemp%"
)

set "cmdlineorig=!cmdline!"
if not "!cmdline!" == "" call set "cmdline=!cmdline!"

call :fileN "fileN" "!listOri!"
set "listTmpSF=%temp%\!fileN!.tmp"
set "linecount=0"

for /f "usebackq tokens=* delims=" %%a in ("!listOri!") do (
    call set "readline=%%~a"

    if "%%~a" == "" (

        echo/Empty line never found^!
        echo/Empty line never found^!
        echo/Empty line never found^!
        echo/Empty line never found^!
        echo/Empty line never found^!
        echo/Empty line never found^!

        if !linecount! leq 0 (
            echo/%%~a>"%listTmpSF%"
        ) else (
            echo/%%~a>>"%listTmpSF%"
        )

    ) else if "!readline!" == "!cmdlineorig!" (

        ::mark unexecuted command
        if !linecount! leq 0 (
            echo/!annoSign!%%~a>"%listTmpSF%"
        ) else (
            echo/!annoSign!%%~a>>"%listTmpSF%"
        )

    ) else if "!readline!" == "!cmdline!" (

        ::mark unexecuted command
        if !linecount! leq 0 (
            echo/!annoSign!%%~a>"%listTmpSF%"
        ) else (
            echo/!annoSign!%%~a>>"%listTmpSF%"
        )

    ) else if "!readline!" == "%annoSignFail%!cmdlineorig!" (

        ::mark failed command
        set "cmmndtemp=%%~a"
        set "cmmndtemp=!cmmndtemp:~4!"
        if !linecount! leq 0 (
            echo/!annoSign!!cmmndtemp!>"%listTmpSF%"
        ) else (
            echo/!annoSign!!cmmndtemp!>>"%listTmpSF%"
        )

    ) else if "!readline!" == "%annoSignFail%!cmdline!" (

        ::mark failed command
        set "cmmndtemp=%%~a"
        set "cmmndtemp=!cmmndtemp:~4!"
        if !linecount! leq 0 (
            echo/!annoSign!!cmmndtemp!>"%listTmpSF%"
        ) else (
            echo/!annoSign!!cmmndtemp!>>"%listTmpSF%"
        )

    ) else (

        ::mark anything other lines
        if !linecount! leq 0 (
            echo/%%~a>"%listTmpSF%"
        ) else (
            echo/%%~a>>"%listTmpSF%"
        )
    )
    set /a "linecount=linecount+1"
)
copy/y "%listTmpSF%" "!listOri!" >nul
set "errlvl=%errorlevel%"

(endlocal
    set "errlvl=%errlvl%"
)
exit/b %errlvl%
:: -----------------------------------------------------------------------------
:fileN  -- Mark executed command line in file as commented
::      -- %~1, result receiver
::      -- %~2, the file to get basename
setlocal

set errlvl=0
if "%~1" == "" set errlvl=1
if "%~2" == "" set errlvl=1
(endlocal
    if %errlvl% leq 0 set "%~1=%~n2"
    set "errlvl=%errlvl%"
)
exit/b %errlvl%
:: -----------------------------------------------------------------------------
:delay          -- Delay for miniseconds set from argument 1.
::              -- Interval     how long to delay (ms).
::                      if interval is not set, will default to 1000 mss.
@echo off
setlocal disabledelayedexpansion

set "interval=%~1"
if %interval% leq 0 set interval=0
ping 192.0.2.2 -n 1 -w %interval% >nul 2>nul

:eoa
endlocal
goto :eof
:: -----------------------------------------------------------------------------
