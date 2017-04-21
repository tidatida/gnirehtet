@ECHO OFF
CALL :locate_file ADB "%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"
CALL :locate_file JAVA "%JAVA_HOME%\bin\java.exe"
CALL :locate_file APK %~dp0gnirehtet.apk %~dp0app\build\outputs\apk\gnirehtet-release.apk %~dp0app\build\outputs\apk\gnirehtet-debug.apk
CALL :locate_file RELAY %~dp0relay.jar %~dp0relay\build\libs\relay.jar

::main
IF NOT "%2"=="" SET serial="-s %2"
CALL :do_%1 %serial% 2>NUL || CALL :do_help 
GOTO :eof

:do_help
    ECHO Syntax: %~nx0 (install^|uninstall^|rt^|start^|stop^|relay^|killserver^|kill) ...
    ECHO.
    ECHO  %~nx0 install [serial]
    ECHO      Install the client on the Android device and exit.
    ECHO      If several devices are connected via adb, then serial must be
    ECHO      specified.
    ECHO.
    ECHO  %~nx0 uninstall [serial]
    ECHO      Uninstall the client from the Android device and exit.
    ECHO      If several devices are connected via adb, then serial must be
    ECHO      specified.
    ECHO.         
    ECHO  %~nx0 reinstall [serial]
    ECHO      Uninstall then install.
    ECHO.
    ECHO  %~nx0 rt [serial] [DNS[,DNS2,...]]
    ECHO      Enable reverse tethering for exactly one device:
    ECHO        - install the client if necessary;"
    ECHO        - start the client;
    ECHO        - start the relay server;
    ECHO        - You'll have to stop the client and the server manually
    ECHO.         
    ECHO  %~nx0 start [serial] [DNS[,DNS2,...]]
    ECHO      Start a client on the Android device and exit.
    ECHO      If several devices are connected via adb, then serial must be
    ECHO      specified.
    ECHO      If DNS is given, then make the Android device use the specified
    ECHO      DNS server(s). Otherwise, use 8.8.8.8 (Google public DNS).
    ECHO      If the client is already started, then do nothing, and ignore
    ECHO      DNS servers parameter.
    ECHO      To use the host 'localhost' as DNS, use 10.0.2.2.
    ECHO.
    ECHO  %~nx0 stop [serial]
    ECHO      Stop the client on the Android device and exit.
    ECHO      If several devices are connected via adb, then serial must be
    ECHO      specified.
    ECHO.     
    ECHO  %~nx0 relay
    ECHO      Start the relay server in the current terminal.
    ECHO.     
    ECHO  %~nx0 killserver
    ECHO      Kills the relay server which opened from this utility.
    ECHO.   
    ECHO  %~nx0 kill [serial]
    ECHO      Kills the relay server and the Android client.
    ECHO      If several devices are connected via adb, then serial must be
    ECHO      specified.
    ENDLOCAL
    EXIT /B


:locate_file
    SETLOCAL EnableDelayedExpansion
    FOR /f " tokens=1*" %%a IN ("%*") DO (
        SET VAR_NAME=%%a
        SET ALL_BUT_FIRST=%%b
    )
    FOR %%G IN (%ALL_BUT_FIRST%) DO (
    IF EXIST %%G (
        SET FNAME=%%G
        )
    )
    IF "!FNAME!"=="" (
        SET FNAME=%2 & ECHO cannot find file, using default name %2
        )
    endlocal&set %VAR_NAME%=%FNAME%
    EXIT /B

:do_install
    ECHO 'Installing gnirehtet...'
    @ECHO ON
    CALL %ADB% %~1 install %APK%
    @ECHO OFF
    EXIT /B

:do_uninstall 
    ECHO 'Uninstall gnirehtet...'
    @ECHO ON
    CALL %ADB% %~1 uninstall com.genymobile.gnirehtet
    @ECHO OFF
    EXIT /B

:do_reinstall
    SETLOCAL
    call :do_uninstall %1
    call :do_install %1
    ENDLOCAL
    EXIT /B

:do_stop
    ECHO 'Stopping gnirehtet...'
    CALL %ADB% %~1 shell am startservice -a com.genymobile.gnirehtet.STOP
    EXIT /B

:do_relay
    ECHO 'Starting relay server...'
    @ECHO ON
    START /I "gnirehtet_relay_server" %JAVA% -jar %RELAY%
    @ECHO OFF
    EXIT /B

:do_start
    SETLOCAL
    FOR /f " tokens=1*" %%a IN ("%*") DO (
        set ALL_BUT_FIRST=%%b
    )
    IF NOT "%ALL_BUT_FIRST%"=="" (
        set dparam="--esa dnsServers %ALL_BUT_FIRST%"
    )
    ECHO 'Starting gnirehtet...'
    @ECHO ON
    CALL %ADB% %~1 reverse tcp:31416 tcp:31416
    CALL %ADB% %~1 shell am startservice -a com.genymobile.gnirehtet.START %dparam%
    @ECHO OFF
    ENDLOCAL
    EXIT /B

:do_killserver
    SETLOCAL EnableDelayedExpansion
    set filter="WINDOWTITLE EQ gnirehtet_relay_server"
    @ECHO ON
    FOR /F "tokens=2" %%I in ('"TASKLIST /NH /FI %filter%"') DO SET PID=%%I 2>1
    TASKKILL /PID !PID!
    @ECHO OFF
    ENDLOCAL
    EXIT /B

:do_rt
    CALL :do_install %1
    CALL :do_relay
    CALL :do_start %1
    EXIT /B

:do_kill
    CALL :do_stop %1
    CALL :do_killserver
    EXIT /B
