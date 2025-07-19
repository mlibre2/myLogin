#pragma compile(FileDescription, Login secondary lock screen Windows)
#pragma compile(ProductName, myLogin)
#pragma compile(ProductVersion, 1.5)
#pragma compile(LegalCopyright, © by mlibre2)
#pragma compile(FileVersion, 1.5)
#pragma compile(Icon, 'C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Threat.contrast-white.ico')

Global Const $sVersion = "1.5"

#NoTrayIcon

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <Crypt.au3>
#include <StringConstants.au3>

; Global configuration
Global $sPassHash = ""
Global $TransparencyGUI = 150       ; 0-255 (transparent-opaque) fullscreen
Global $TransparencyPassGUI = 180   ; 0-255 (transparent-opaque) for window
Global $iColorTxt = 0xFFFFFF        ; Text color
Global $iBkColorGUI = 0x000000      ; Background color (full)
Global $iBkColorPassGUI = 0xFFFFFF  ; Background color (window)
Global $iWidthPassGUI = 350         ; Window width
Global $iHighPassGUI = 195          ; Window height
Global $iFail = 0                   ; Failed attempts (login)
Global $iStyle = 0                  ; Color style (0=white/1=dark/2=aqua)
Global $bDisableExplorer = False    ; Disable Windows Explorer
Global $bDisableTaskMgr = False     ; Disable Task Manager
Global $bDisablePowerOff = False    ; Disable system Shutdown button
Global $bDisableReboot = False      ; Disable system Reboot button
Global $sLanguage = "en"; _getOSLang()	; Get language (system)

; Language strings (will be loaded from INI)
Global $aLangStrings[1]

Global Const $sExplorer = "explorer.exe"
Global $bProcessExists = ProcessExists($sExplorer) > 0	; Check if a process exists

; Load language files
_LoadLanguage()

;~ Check and prevent double execution
If (ProcessList(@ScriptName)[0][0] >= 2) Then
   MsgBox($MB_ICONWARNING, @ScriptName, _getLang("program_already_open"), 3)
   Exit
EndIf

; ...command line
_ProcessParameters()

;~ Check parameters
If $bDisableExplorer And $bProcessExists Then
   Run("cmd /c taskkill /f /im " & $sExplorer, "", "", @SW_HIDE)

ElseIf Not $bProcessExists Then
   ; Read Shell key value
   Local $sRegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
   Local $sRegValue = "Shell"
   Local $sShellValue = RegRead($sRegPath, $sRegValue)

   If Not StringInStr($sShellValue, $sExplorer) > 0 Then
      RegWrite($sRegPath, $sRegValue, "REG_SZ", $sExplorer)

      MsgBox($MB_ICONWARNING, _getLang("explorer_error_title"), _getLang("explorer_error_msg") & @CRLF & @CRLF & $sRegValue & " " & _getLang("from_winlogon") & ": " & @CRLF & @CRLF & $sShellValue & @CRLF & @CRLF & _getLang("explorer_fix_msg"))

      Run("cmd /c shutdown /r /f /t 0", "", "", @SW_HIDE)
      Exit
   Else
	  $bDisableExplorer = True
   EndIf
EndIf

If $bDisableTaskMgr Then
   RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "1")
EndIf

; Check single instance
If _Singleton("ScreenLockWindow", 1) = 0 Then Exit

; Create main window (fullscreen)
Local $hGUI = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUISetBkColor($iBkColorGUI, $hGUI)
WinSetTrans($hGUI, "", $TransparencyGUI)
GUISetState(@SW_SHOW, $hGUI)

; Create password window (centered)
Local $hPassGUI = GUICreate("", $iWidthPassGUI, $iHighPassGUI, -1, -1, $WS_POPUP, $WS_EX_TOPMOST, $hGUI)
GUISetBkColor($iBkColorPassGUI, $hPassGUI)
WinSetTrans($hPassGUI, "", $TransparencyPassGUI)

; Position controls
Local $idIcoPass = GUICtrlCreateIcon("shell32.dll", -245, ($iWidthPassGUI - 32) / 2, 10, 32, 32)
GUICtrlSetTip(-1, _getLang("restricted_access"))

Local $idTxtPass = GUICtrlCreateLabel(_getLang("system_locked"), 10, 45, $iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 12, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idTxtMsg = GUICtrlCreateLabel(_getLang("enter_password"), 10, 65, $iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idInput = GUICtrlCreateInput("", 50, 90, $iWidthPassGUI - 100, 20, $ES_PASSWORD)
GUICtrlSetState(-1, $GUI_FOCUS)

Local $idErrorLabel = GUICtrlCreateLabel("", 10, 120, $iWidthPassGUI - 20, 20, $SS_CENTER)
GUICtrlSetColor(-1, $iStyle > 0 ? 0xFFEC00 : 0xFF0000)
GUICtrlSetFont(-1, 8, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")

Local $idButtonUnlock = GUICtrlCreateButton(-1, 290, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -177)
GUICtrlSetTip(-1, _getLang("unlock"))

Local $idPowerOff = GUICtrlCreateButton(-1, 20, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetState(-1, $bDisablePowerOff ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("shutdown"))

Local $idReboot = GUICtrlCreateButton(-1, 65, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -239)
GUICtrlSetState(-1, $bDisableReboot ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("reboot"))

GUICtrlCreateLabel(_getLang("start_time") & " " & _Time(), 135, 160)
GUICtrlSetFont(-1, 8, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

GUICtrlCreateLabel("MyLogin v" & $sVersion, 295, 5)
GUICtrlSetFont(-1, 6, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Center and show window
WinMove($hPassGUI, "", (@DesktopWidth - $iWidthPassGUI) / 2, (@DesktopHeight - $iHighPassGUI) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Block special keys
Local $aHotKeys = ["{F4}","{DEL}","{TAB}","{HOME}","{ESC}","{UP}","{DOWN}","{LEFT}","{RIGHT}","{SPACE}"]

For $sKey In $aHotKeys
    HotKeySet($sKey, "_BlockKeys")
Next

; Main loop
While 1
   Switch GUIGetMsg()
      Case $GUI_EVENT_CLOSE, $idButtonUnlock
         If _VerifyPassword() Then
            GUICtrlSetImage($idIcoPass, "imageres.dll", -102)
            GUISetBkColor(0x0FFF00, $hGUI)

            GUICtrlSetData($idTxtPass, _getLang("unlocked"))
            GUICtrlSetColor($idTxtPass, $iStyle > 0 ? 0x0FFF00 : 0x0F9800)

            GUICtrlSetData($idTxtMsg, "")

            If $iFail > 0 Then
               GUICtrlSetData($idErrorLabel, "")
            EndIf

            ; Restore Windows Explorer if disabled
            If $bDisableExplorer Then
               Run(@WindowsDir & "\" & $sExplorer, "", @SW_HIDE)
            EndIf

            ; Restore Task Manager if disabled
            If $bDisableTaskMgr Then
               RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "0")
            EndIf

            SoundPlay(@WindowsDir & "\media\ding.wav", $SOUND_NOWAIT)

			Sleep(400)

            ExitLoop
         EndIf

         $iFail += 1

         GUICtrlSetData($idErrorLabel, "(" & $iFail & ") " & _getLang("incorrect_password"))
         GUICtrlSetData($idInput, "")
         GUICtrlSetState($idInput, $GUI_FOCUS)

         SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

         GUICtrlSetImage($idIcoPass, "imageres.dll", -101)
         GUISetBkColor(0xFF0000, $hGUI)

         Sleep(300)

         GUICtrlSetImage($idIcoPass, "shell32.dll", -245)
         GUISetBkColor($iBkColorGUI, $hGUI)

      Case $idPowerOff
         Run("cmd /c shutdown /s /f /t 0", "", "", @SW_HIDE)
         GUICtrlSetState($idPowerOff, $GUI_DISABLE)
         GUICtrlSetState($idReboot, $GUI_DISABLE)

      Case $idReboot
         Run("cmd /c shutdown /r /f /t 0", "", "", @SW_HIDE)
         GUICtrlSetState($idPowerOff, $GUI_DISABLE)
         GUICtrlSetState($idReboot, $GUI_DISABLE)
   EndSwitch
WEnd

; Cleanup and exit
GUIDelete($hPassGUI)
GUIDelete($hGUI)
Exit

;~ Functions
Func _VerifyPassword()
   Return (_getHash(GUICtrlRead($idInput)) = $sPassHash)
EndFunc

Func _BlockKeys()
    SoundPlay(@WindowsDir & "\media\Windows Hardware Fail.wav", $SOUND_NOWAIT)
EndFunc

Func _getHash($sInput)
   Local $sHash = _Crypt_HashData($sInput, 0x0000800e) ; sha512
   Return _Crypt_HashData($sHash, $CALG_MD5) ; 128-bit
EndFunc

Func _Time()
   Local $h24 = @HOUR
   Local $apm = "a"

   If $h24 >= 12 Then
      $apm = "p"
      If $h24 > 12 Then $h24 -= 12
   ElseIf $h24 = 0 Then
      $h24 = 12
   EndIf

   Return $h24 & ":" & @MIN & " " & $apm & "m"
EndFunc

Func _GenerateNewHash()
   Local $bValid = False
   Local $sInput = ""

   ; Loop until valid password is entered
   While Not $bValid
      $sInput = InputBox(_getLang("hash_generator_title"), _getLang("hash_generator_msg") & @CRLF & @CRLF & "- " & _getLang("min_chars") & @CRLF & "- " & _getLang("no_spaces"), "", "*")

      ; If user cancels
      If @error Then
         MsgBox($MB_ICONINFORMATION, _getLang("info"), _getLang("hash_generation_canceled"))
         If $bProcessExists Then
            Exit
         EndIf
      EndIf

      ; Validations
      If StringLen($sInput) < 2 Then
         MsgBox($MB_ICONWARNING, _getLang("error"), _getLang("min_chars_error"))
      ElseIf StringIsSpace($sInput) Then
         MsgBox($MB_ICONWARNING, _getLang("error"), _getLang("spaces_only_error"))
      ElseIf StringInStr($sInput, " ") Then
         MsgBox($MB_ICONWARNING, _getLang("error"), _getLang("spaces_not_allowed_error"))
      Else
         $bValid = True
      EndIf
   WEnd

   ; Generate and display hash
   InputBox(_getLang("generated_hash_title"), _getLang("generated_hash_msg") & @CRLF & @CRLF & $sInput & @CRLF & @CRLF & _getLang("your_new_hash"), _getHash($sInput))
EndFunc

Func _ProcessParameters()
   For $i = 1 To $CmdLine[0]
      Switch $CmdLine[$i]
         Case "/GenerateHash", "/gh"
            _GenerateNewHash()
            If $bProcessExists Then
               Exit
            EndIf

         Case "/PassHash", "/ph"
            If $i + 1 <= $CmdLine[0] Then
               $sPassHash = $CmdLine[$i + 1]
               $i += 1 ; Skip to next parameter

               ; Basic hash validation
               If StringLen($sPassHash) <> 34 Or StringLeft($sPassHash, 2) <> "0x" Then
                  MsgBox($MB_ICONERROR, _getLang("error_title"), _getLang("invalid_hash") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("generate_hash_help") & @CRLF & @CRLF & @ScriptName & " /GenerateHash")
                  If $bProcessExists Then
                     Exit
                  EndIf
               EndIf
            EndIf

         Case "/DisableTaskMgr", "/dt"
            $bDisableTaskMgr = True

         Case "/DisableExplorer", "/de"
            $bDisableExplorer = True

         Case "/DisablePowerOff", "/dp"
            $bDisablePowerOff = True

         Case "/DisableReboot", "/dr"
            $bDisableReboot = True

         Case "/Style", "/st"
            If $i + 1 <= $CmdLine[0] Then
               $iStyle = $CmdLine[$i + 1]
               $i += 1

               Switch $iStyle
                  Case "1"   ; dark
                     $iBkColorPassGUI = 0x050505
                  Case "2"   ; aqua
                     $iBkColorPassGUI = 0x00696D
               EndSwitch
            EndIf

      EndSwitch
   Next

   If $sPassHash = "" Then
      Local $iButton = MsgBox($MB_RETRYCANCEL, _getLang("error_title"), _getLang("missing_hash") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("generate_hash_help") & @CRLF & @CRLF & @ScriptName & " /GenerateHash" & @CRLF & @CRLF & @CRLF & _getLang("generate_now"))

      If $iButton = $IDOK Then
         _GenerateNewHash()
      EndIf

      If $bProcessExists Then
         Exit
      EndIf
   EndIf
EndFunc

Func _LoadLanguage()
   Local $sLangPath = @ScriptDir & "\lang"
   Local $sLangFile = $sLangPath & "\" & $sLanguage & ".ini"

   ; Check if language folder exists
   If Not FileExists($sLangPath) Then
      MsgBox($MB_ICONERROR, "Error", "Language folder not found at:" & @CRLF & $sLangPath)
      Exit
   EndIf

   ; Check if requested language file exists, fallback to English if not
   If Not FileExists($sLangFile) Then
      $sLangFile = $sLangPath & "\en.ini"

      If Not FileExists($sLangFile) Then
         MsgBox($MB_ICONERROR, "Error", "Default language file (en.ini) not found at:" & @CRLF & $sLangPath)
         Exit
      EndIf
   EndIf

   ; Read file with proper encoding handling
   Local $hFile = FileOpen($sLangFile, $FO_UTF8_NOBOM + $FO_READ)
   If $hFile = -1 Then
      MsgBox($MB_ICONERROR, "Error", "Unable to open language file:" & @CRLF & $sLangFile)
      Exit
   EndIf

   Local $sIniContent = FileRead($hFile)
   FileClose($hFile)

   ; Parse the INI content manually
   $aLangStrings = _ParseIniSection($sIniContent, $sLanguage)

   If @error Then
      MsgBox($MB_ICONERROR, "Error", "Invalid language file format in:" & @CRLF & $sLangFile)
      Exit
   EndIf
EndFunc

Func _ParseIniSection($sIniContent, $sSection)
   Local $aResult[1][2], $iCount = 0
   Local $bInSection = False
   Local $aLines = StringSplit(StringStripCR($sIniContent), @LF)

   For $i = 1 To $aLines[0]
      Local $sLine = StringStripWS($aLines[$i], $STR_STRIPLEADING + $STR_STRIPTRAILING)

      ; Skip empty lines and comments
      If $sLine = "" Or StringLeft($sLine, 1) = ";" Then ContinueLoop

      ; Check for section
      If StringLeft($sLine, 1) = "[" And StringRight($sLine, 1) = "]" Then
         $bInSection = (StringMid($sLine, 2, StringLen($sLine)-2) = $sSection)
         ContinueLoop
      EndIf

      ; If we're in the right section, parse key=value
      If $bInSection Then
         Local $iEqualsPos = StringInStr($sLine, "=")
         If $iEqualsPos > 0 Then
            $iCount += 1
            ReDim $aResult[$iCount+1][2]
            $aResult[$iCount][0] = StringStripWS(StringLeft($sLine, $iEqualsPos-1), $STR_STRIPLEADING + $STR_STRIPTRAILING)
            $aResult[$iCount][1] = StringStripWS(StringMid($sLine, $iEqualsPos+1), $STR_STRIPLEADING + $STR_STRIPTRAILING)
         EndIf
      EndIf
   Next

   $aResult[0][0] = $iCount
   Return $aResult
EndFunc

Func _getLang($sKey)
   For $i = 1 To $aLangStrings[0][0]
      If $aLangStrings[$i][0] = $sKey Then
         Return $aLangStrings[$i][1]
      EndIf
   Next
   Return "[" & $sKey & "]" ; Return key name if not found
EndFunc

Func _getOSLang()
   Local $iLangCode = @OSLang

   Local $aLanguageMap[][2] = [ _
	  ["0436", "af"], _
	  ["045E", "am"], _
	  ["0401", "ar"], ["0801", "ar"], ["0C01", "ar"], ["1001", "ar"], ["1401", "ar"], ["1801", "ar"], ["1C01", "ar"], ["2001", "ar"], ["2401", "ar"], ["2801", "ar"], ["2C01", "ar"], ["3001", "ar"], ["3401", "ar"], ["3801", "ar"], ["3C01", "ar"], ["4001", "ar"], _
	  ["042B", "hy"], _
	  ["042C", "az"], ["082C", "az"], _
	  ["044D", "as"], _
	  ["0423", "be"], _
	  ["0445", "bn"], ["0845", "bn"], _
	  ["0402", "bg"], _
	  ["0455", "my"], _
	  ["0403", "ca"], ["0803", "ca"], _
	  ["0004", "zh"], ["0804", "zh"], ["0C04", "zh"], ["1004", "zh"], ["1404", "zh"], ["0404", "zh"], ["7C04", "zh"], _
	  ["041A", "hr"], ["101A", "hr"], _
	  ["0405", "cs"], _
	  ["0406", "da"], _
	  ["048C", "prs"], _
	  ["0465", "dv"], _
	  ["0413", "nl"], ["0813", "nl"], _
	  ["0409", "en"], ["0809", "en"], ["0C09", "en"], ["1009", "en"], ["1409", "en"], ["1809", "en"], ["1C09", "en"], ["2009", "en"], ["2409", "en"], ["2809", "en"], ["2C09", "en"], ["3009", "en"], ["3409", "en"], ["4009", "en"], ["4409", "en"], ["4809", "en"], _
	  ["0425", "et"], _
	  ["0463", "ps"], _
	  ["040B", "fi"], _
	  ["040C", "fr"], ["080C", "fr"], ["0C0C", "fr"], ["100C", "fr"], ["140C", "fr"], ["180C", "fr"], _
	  ["0462", "fy"], _
	  ["0456", "gl"], _
	  ["0457", "kok"], _
	  ["0407", "de"], ["0807", "de"], ["0C07", "de"], ["1007", "de"], ["1407", "de"], _
	  ["0408", "el"], _
	  ["046F", "kl"], _
	  ["0447", "gu"], _
	  ["040D", "he"], _
	  ["0439", "hi"], _
	  ["040E", "hu"], _
	  ["040F", "is"], _
	  ["0421", "id"], _
	  ["0470", "ig"], _
	  ["0410", "it"], ["0810", "it"], _
	  ["0411", "ja"], _
	  ["044B", "kn"], _
	  ["043F", "kk"], _
	  ["0451", "bo"], _
	  ["0412", "ko"], _
	  ["0492", "ku"], _
	  ["0440", "ky"], _
	  ["0426", "lv"], _
	  ["0427", "lt"], _
	  ["042E", "hsb"], ["082E", "dsb"], _
	  ["0430", "tn"], ["0432", "tn"], ["0832", "tn"], _
	  ["0434", "zu"], ["0435", "zu"], _
	  ["042F", "mk"], _
	  ["044C", "ml"], _
	  ["043A", "mt"], _
	  ["0458", "mni"], _
	  ["0450", "mn"], ["0850", "mn"], _
	  ["043E", "ms"], ["083E", "ms"], _
	  ["044E", "mr"], _
	  ["0475", "haw"], _
	  ["0414", "no"], ["0814", "no"], _
	  ["0448", "or"], _
	  ["0461", "ne"], _
	  ["0415", "pl"], _
	  ["0416", "pt"], ["0816", "pt"], _
	  ["0446", "pa"], _
	  ["046B", "quz"], ["086B", "quz"], ["0C6B", "quz"], _
	  ["0418", "ro"], _
	  ["0419", "ru"], _
	  ["0487", "rw"], _
	  ["044F", "sa"], _
	  ["043B", "se"], ["083B", "se"], ["0C3B", "se"], _
	  ["081A", "sr"], ["041A", "sr"], ["101A", "sr"], _
	  ["0459", "sd"], ["0859", "sd"], _
	  ["041D", "sv"], ["081D", "sv"], _
	  ["045B", "si"], _
	  ["0424", "sl"], _
	  ["041B", "sk"], _
	  ["043C", "gd"], ["0491", "gd"], _
	  ["040A", "es"], ["080A", "es"], ["0C0A", "es"], ["100A", "es"], ["140A", "es"], ["180A", "es"], ["1C0A", "es"], ["200A", "es"], ["240A", "es"], ["280A", "es"], ["2C0A", "es"], ["300A", "es"], ["340A", "es"], ["380A", "es"], ["3C0A", "es"], ["400A", "es"], ["440A", "es"], ["480A", "es"], ["4C0A", "es"], ["500A", "es"], ["540A", "es"], _
	  ["0441", "sw"], _
	  ["041E", "th"], _
	  ["0437", "ka"], _
	  ["045A", "syr"], _
	  ["0449", "ta"], ["0849", "ta"], _
	  ["044A", "te"], _
	  ["041F", "tr"], _
	  ["0444", "tt"], _
	  ["045F", "tzm"], ["085F", "tzm"], ["105F", "tzm"], _
	  ["0422", "uk"], _
	  ["0420", "ur"], ["0820", "ur"], _
	  ["0443", "uz"], ["0843", "uz"], _
	  ["042A", "vi"], _
	  ["0452", "cy"], _
	  ["046A", "yo"]]

   ; Find the language code in the table
   For $i = 0 To UBound($aLanguageMap) - 1
	  If $aLanguageMap[$i][0] = $iLangCode Then
		 Return $aLanguageMap[$i][1]
	  EndIf
   Next

   ; If not found, return English by default
   Return "en"
EndFunc
