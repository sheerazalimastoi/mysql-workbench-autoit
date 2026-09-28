#Region ; =====================================================================
; MySQL Workbench - Temporary Connection Creator / Launcher
; ============================================================================

; Tested with:
;   AutoIt v3.3.18.0
;   MySQL Workbench 26.7.0.0
;
; PURPOSE:
;   This script automates the creation and launching of a MySQL Workbench
;   database connection by performing the required GUI operations.
;
;   The script:
;       1. Launches / activates MySQL Workbench.
;       2. Closes any previously active SQL connection/session using CTRL+SHIFT+W.
;       3. Opens the "Database Connection Configuration" window.
;       4. Uses the supplied Host/IP as the connection Caption.
;       5. Enters the database Host/IP.
;       6. Enters the database Username.
;       7. Stores the supplied database Password.
;       8. Saves the new connection.
;       9. Launches the newly created connection.
;      10. Returns to Home and deletes the saved connection definition.
;      11. Returns to the active SQL connection.
;
; COMMAND-LINE USAGE:
;
;   AutoIt3.exe CreateAndOpenWorkbenchConnection.au3 [Host] [User] [Password]
;
; Example:
;
;   AutoIt3.exe CreateAndOpenWorkbenchConnection.au3 _
;       "10.10.10.25" "dbuser" "SecretPassword"
;
; ARGUMENT MAPPING:
;
;   Argument 1 = MySQL Hostname / IP Address
;   Argument 2 = MySQL Username
;   Argument 3 = MySQL Password
;
; CONNECTION CAPTION:
;
;   The Hostname / IP Address supplied in Argument 1 is also used as the
;   Workbench Connection Caption.
;
; SECURITY NOTE:
;
;   Command-line arguments can potentially be visible to other processes
;   running with sufficient privileges.
;
;   When this script is integrated with BeyondTrust Password Safe,
;   credentials should preferably be supplied using the Password Safe
;   application credential-injection / passthrough mechanism rather than
;   manually exposing credentials.
;
#EndRegion ; ==================================================================


; =============================================================================
; SECTION 01 - REQUIRED AUTOIT LIBRARIES
; =============================================================================

; Required for MsgBox constants used by the _Fail() function.
#include <MsgBoxConstants.au3>


; =============================================================================
; SECTION 02 - AUTOIT RUNTIME OPTIONS
; =============================================================================

; Exact / advanced window title matching.
Opt("WinTitleMatchMode", 4)

; Reduce the default delay AutoIt places after window operations.
Opt("WinWaitDelay", 100)

; Mouse coordinates used by MouseClick() are absolute screen coordinates.
Opt("MouseCoordMode", 1)


; =============================================================================
; SECTION 03 - MYSQL WORKBENCH CONFIGURATION
; =============================================================================

; Full installation path of MySQL Workbench.
Global Const $g_sWorkbenchExe = _
        "C:\Program Files\MySQL\MySQL Workbench\MySQL Workbench.exe"

; Main MySQL Workbench window identifier.
Global Const $g_sWorkbenchWindow = _
        "[TITLE:MySQL Workbench; CLASS:Chrome_WidgetWin_1]"

; Maximum number of seconds to wait for Workbench to appear.
Global Const $g_iWaitSeconds = 10

; Workbench 26 uses an Electron interface.
; Allow the Home screen enough time to finish loading before automation begins.
Global Const $g_iStartupDelayMs = 8000

; Delay after clicking the "+" New Connection button.
Global Const $g_iAfterNewConnectionClickDelayMs = 300


; =============================================================================
; SECTION 04 - READ DATABASE PARAMETERS
; =============================================================================
;
; Password Safe / command line supplies:
;
;   Parameter 1 = Hostname / IP
;   Parameter 2 = Username
;   Parameter 3 = Password
;

Global $g_sHost = _ArgOrDefault(1, "")
Global $g_sUser = _ArgOrDefault(2, "")
Global $g_sPassword = _ArgOrDefault(3, "")

; Main Workbench window handle.
Global $g_hWorkbench = 0


; =============================================================================
; SECTION 05 - VALIDATE REQUIRED PARAMETERS
; =============================================================================

; Hostname/IP and Username are mandatory.
If $g_sHost = "" Or $g_sUser = "" Then

    _Fail("Usage: " & @ScriptName & _
            " [Host] [User] [Password]" & @CRLF & _
            "Host and User are required.")

EndIf


; =============================================================================
; SECTION 06 - VERIFY MYSQL WORKBENCH INSTALLATION
; =============================================================================

; Stop immediately if the configured Workbench executable does not exist.
If Not FileExists($g_sWorkbenchExe) Then

    _Fail("MySQL Workbench was not found at:" & _
            @CRLF & $g_sWorkbenchExe)

EndIf


; =============================================================================
; SECTION 07 - LAUNCH AND ACTIVATE MYSQL WORKBENCH
; =============================================================================

; Launch MySQL Workbench from its configured installation path.
Run('"' & $g_sWorkbenchExe & '"')

; Wait for the main MySQL Workbench window.
$g_hWorkbench = WinWait( _
        $g_sWorkbenchWindow, _
        "", _
        $g_iWaitSeconds)

If $g_hWorkbench = 0 Then

    _Fail("MySQL Workbench did not open within " & _
            $g_iWaitSeconds & " seconds.")

EndIf

; Bring Workbench to the foreground before sending any keyboard/mouse input.
WinActivate($g_hWorkbench)

If Not WinWaitActive($g_hWorkbench, "", 5) Then

    _Fail("MySQL Workbench could not be activated. " & _
            "No input was sent.")

EndIf

; Allow the Workbench 26 Electron Home interface to finish rendering.
Sleep($g_iStartupDelayMs)


; =============================================================================
; SECTION 08 - CLOSE PREVIOUS ACTIVE SQL CONNECTION / SESSION
; =============================================================================
;
; CTRL + SHIFT + W is sent before beginning the new connection workflow.
;
; Purpose:
;   Ensure that a previous SQL connection/session does not remain selected
;   and interfere with the automation sequence or cause the script to work
;   against an unintended existing session.
;

Send("^+w")

; Small delay so Workbench can process the shortcut before continuing.
Sleep(500)


; =============================================================================
; SECTION 09 - OPEN DATABASE CONNECTION CONFIGURATION
; =============================================================================

; Click the "+" button on the Workbench Home screen to create a new
; database connection.
Local $hEditor = _OpenNewConnectionByClick($g_hWorkbench)

If $hEditor = 0 Then

    _Fail("The Database Connection Configuration window did not appear.")

EndIf

; Ensure the Workbench window containing the embedded configuration
; interface is active.
WinActivate($hEditor)
WinWaitActive($hEditor, "", 3)


; =============================================================================
; SECTION 10 - POPULATE AND SAVE DATABASE CONNECTION
; =============================================================================
;
; Populate:
;
;   Caption  = Hostname / IP
;   Host     = Hostname / IP
;   Username = Supplied database username
;   Password = Supplied database password
;
; The existing verified coordinates are intentionally retained.
;

_PopulateAndSaveConnectionWithKeyboard($hEditor)


; =============================================================================
; SECTION 11 - LAUNCH THE SAVED MYSQL CONNECTION
; =============================================================================

; Activate the main Workbench window.
WinActivate($g_hWorkbench)

; Click the newly created connection tile.
MouseClick("left", 425, 200, 1, 10)

; Allow the SQL connection/session to initialize.
Sleep(3000)


; =============================================================================
; SECTION 12 - RETURN TO HOME SCREEN
; =============================================================================

; Open the Workbench connection/navigation dropdown.
MouseClick("left", 400, 70, 1, 10)

; Select Home.
MouseClick("left", 400, 130, 1, 10)


; =============================================================================
; SECTION 13 - DELETE THE SAVED CONNECTION DEFINITION
; =============================================================================
;
; The database session has already been launched.
;
; The saved Workbench connection definition is now removed so that the
; Workbench Home screen does not retain this temporary connection for a
; subsequent Password Safe / RemoteApp user.
;

; Click the three-dot menu associated with the saved connection.
MouseClick("left", 540, 200, 1, 10)

; Navigate through the context menu to the Delete option.
Send("{DOWN 8}")

; Select the highlighted menu option.
Send("{ENTER}")

; Confirm deletion of the saved Workbench connection.
MouseClick("left", 845, 465, 1, 10)


; =============================================================================
; SECTION 14 - RETURN TO THE ACTIVE SQL CONNECTION
; =============================================================================

; Open the Workbench connection/session dropdown.
MouseClick("left", 400, 70, 1, 10)

; Select the first active SQL connection/session.
MouseClick("left", 400, 170, 1, 10)


; =============================================================================
; FUNCTION 01 - READ COMMAND-LINE ARGUMENT
; =============================================================================
;
; Returns the requested command-line argument.
; If that argument is unavailable or empty, the supplied default value
; is returned instead.
;

Func _ArgOrDefault($iIndex, $sDefault)

    If $CmdLine[0] >= $iIndex And _
            $CmdLine[$iIndex] <> "" Then

        Return $CmdLine[$iIndex]

    EndIf

    Return $sDefault

EndFunc


; =============================================================================
; FUNCTION 02 - POPULATE AND SAVE MYSQL CONNECTION
; =============================================================================
;
; Uses the previously verified Workbench 26 screen coordinates.
;
; IMPORTANT:
;   These mouse coordinates are environment-specific and depend on the
;   RDS / RemoteApp display resolution and Workbench layout remaining
;   consistent.
;

Func _PopulateAndSaveConnectionWithKeyboard($hWnd)

    ; Bring the Workbench configuration interface into focus.
    WinActivate($hWnd)

    If Not WinWaitActive($hWnd, "", 3) Then

        _Fail("MySQL Workbench is not active; " & _
                "connection information was not entered.")

    EndIf


    ; -------------------------------------------------------------------------
    ; 2.1 - CONNECTION CAPTION
    ; -------------------------------------------------------------------------
    ;
    ; Use the database Hostname / IP Address as the Workbench
    ; connection name.
    ;

    MouseClick("left", 420, 165, 1, 10)

    Send("^a")
    Send($g_sHost, 1)


    ; -------------------------------------------------------------------------
    ; 2.2 - DATABASE HOSTNAME / IP ADDRESS
    ; -------------------------------------------------------------------------

    MouseClick("left", 420, 492, 1, 10)

    Send("^a")
    Send($g_sHost, 1)


    ; -------------------------------------------------------------------------
    ; 2.3 - DATABASE USERNAME
    ; -------------------------------------------------------------------------

    MouseClick("left", 445, 550, 1, 10)

    Send("^a")
    Send($g_sUser, 1)


    ; -------------------------------------------------------------------------
    ; 2.4 - STORE DATABASE PASSWORD
    ; -------------------------------------------------------------------------
    ;
    ; Click "Store Password", then enter the password supplied to the script.
    ;

    MouseClick("left", 725, 550, 1, 10)

    Send("^a")
    Send($g_sPassword, 1)


    ; -------------------------------------------------------------------------
    ; 2.5 - CONFIRM PASSWORD
    ; -------------------------------------------------------------------------

    MouseClick("left", 820, 485, 1, 10)


    ; -------------------------------------------------------------------------
    ; 2.6 - SAVE DATABASE CONNECTION
    ; -------------------------------------------------------------------------

    MouseClick("left", 960, 670, 1, 10)

    Sleep(300)

EndFunc


; =============================================================================
; FUNCTION 03 - OPEN NEW DATABASE CONNECTION WINDOW
; =============================================================================
;
; Workbench 26 displays "Database Connection Configuration" as an embedded
; Electron interface rather than as a separate native Windows dialog.
;
; Because of this, the original Workbench window handle continues to be used.
;

Func _OpenNewConnectionByClick($hWnd)

    ; Ensure Workbench is active before clicking its interface.
    WinActivate($hWnd)

    If Not WinWaitActive($hWnd, "", 3) Then
        Return 0
    EndIf

    ; Click the "+" button used to create a new database connection.
    MouseClick("left", 1160, 160, 1, 10)

    Sleep(250)

    ; Allow the embedded Database Connection Configuration screen to render.
    Sleep($g_iAfterNewConnectionClickDelayMs)

    ; Verify the main Workbench window remains active.
    If Not WinActive($hWnd) Then
        Return 0
    EndIf

    ; Return the Workbench handle because the connection editor is embedded
    ; inside this same Electron window.
    Return $hWnd

EndFunc


; =============================================================================
; FUNCTION 04 - ERROR HANDLING
; =============================================================================
;
; Displays an error to the interactive user and terminates the automation
; with exit code 1.
;

Func _Fail($sMessage)

    MsgBox( _
            $MB_ICONERROR, _
            "MySQL Workbench connection automation", _
            $sMessage)

    Exit 1

EndFunc
