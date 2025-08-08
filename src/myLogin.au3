#pragma compile(Icon, 'C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Threat.contrast-white.ico')
#pragma compile(ExecLevel, none)
#pragma compile(UPX, false)
#pragma compile(Compression, 0)
#pragma compile(CompanyName, 'mlibre2')
#pragma compile(FileDescription, Secure lock screen)
#pragma compile(FileVersion, 2.4)					; auto-incremental by workflows (compile)
#pragma compile(LegalCopyright, © by mlibre2 - Open source project on GitHub)
#pragma compile(OriginalFilename, myLogin.exe)
#pragma compile(ProductName, myLogin)
#pragma compile(ProductVersion, 2.4)				; auto-incremental by workflows (compile)

#NoTrayIcon							; Will not be shown when the script starts

#include <GUIConstantsEx.au3>		; GUI Create, events
#include <WindowsConstants.au3>		; Gui extended style
#include <StaticConstants.au3>		; Label, Pic, Icon
#include <ButtonConstants.au3>		; Button, Group, Radio, Checkbox
#include <AutoItConstants.au3>		; Constants
#include <MsgBoxConstants.au3>		; MsgBox related
#include <EditConstants.au3>		; Edit, Input
#include <Misc.au3>					; That assist with Common Dialogs
#include <Crypt.au3>				; Encrypting and hashing data
#include <StringConstants.au3>		; Using String
#include <WinAPIGdi.au3>			; UDF Library
#include <Inet.au3>					; Download updates
#include <FileConstants.au3>		; FileOpen, FileWriteLine and FileClose

; configuration
Const $g_sVersion = "2.4"								; auto-incremental by workflows (compile)
$g_sPassHash = ""
Const $g_iTransparencyGUI = 150							; 0-255 (transparent-opaque) fullscreen
Const $g_iTransparencyPassGUI = 180						; 0-255 (transparent-opaque) for window
$g_iColorTxt = 0xFFFFFF									; Text color
Const $g_iBkColorGUI = 0x000000							; Background color (full)
$g_iBkColorPassGUI = 0xFFFFFF							; Background color (window)
Const $g_iWidthPassGUI = 350							; Window width
Const $g_iHeightPassGUI = 195							; Window height
$g_iFailAttempts = 0									; Failed attempts (login)
$g_iStyle = 0											; Color style (0=white/1=dark/2=aqua)
$g_bDisableExplorer = True								; Disable Windows Explorer
$g_bDisablePowerOff = False								; Disable system Shutdown button
$g_bDisableReboot = False								; Disable system Reboot button
$g_bDisableLockSession = False							; Disable system Lock button
Const $g_sLanguage = _getOSLang()						; Get language (system)
$g_oLangLookup = ObjCreate("Scripting.Dictionary")		; Optimize searches table hash O(1)
Const $g_iPassMinLength = 2								; Define minimum password length
Const $g_iPassMaxLength = 30							; Define maximum password length
Global $g_aButtonsParam[4]								; save/get button parameters
Const $g_sName = "myLogin"								; Script name
Const $g_sComp = ""								; for testing only

; Load language files
_LoadLanguage()

;~ Check single instance prevent double execution
If Not _Singleton($g_sName, 1) Then
   MsgBox($MB_ICONWARNING, @ScriptName, _getLang("PROGRAM_ALREADY_OPEN"), 3)
   Exit
EndIf

; ...command line
_ProcessParameters()

; Create main window (fullscreen)
$hGUI = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUISetBkColor($g_iBkColorGUI, $hGUI)
_EnableBlur($hGUI)
GUISetState(@SW_SHOW, $hGUI)

; Create password window (centered)
$hPassGUI = GUICreate("", $g_iWidthPassGUI, $g_iHeightPassGUI, -1, -1, $WS_POPUP, $WS_EX_TOPMOST, $hGUI)
GUISetBkColor($g_iBkColorPassGUI, $hPassGUI)
WinSetTrans($hPassGUI, "", $g_iTransparencyPassGUI)

; Position controls
GUICtrlCreateLabel(_getLang("START_TIME") & " " & _Time(), 10, 5)
GUICtrlSetFont(-1, 6, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

GUICtrlCreateLabel($g_sName & " v" & $g_sVersion, 285, 5)
GUICtrlSetFont(-1, 6, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

$idIcoPass = GUICtrlCreateIcon("shell32.dll", -245, ($g_iWidthPassGUI - 32) / 2, 10, 32, 32)
GUICtrlSetTip(-1, _getLang("RESTRICTED_ACCESS"))

$idTxtPass = GUICtrlCreateLabel(_getLang("SYSTEM_LOCKED"), 10, 45, $g_iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 12, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

$idTxtMsg = GUICtrlCreateLabel(_getLang("ENTER_PASSWORD"), 10, 65, $g_iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

$idInput = GUICtrlCreateInput("", 50, 90, $g_iWidthPassGUI - 100, 20, $ES_PASSWORD + $ES_CENTER)
GUICtrlSetState(-1, $GUI_FOCUS)

$idErrorLabel = GUICtrlCreateLabel("", 10, 120, $g_iWidthPassGUI - 20, 20, $SS_CENTER)
GUICtrlSetColor(-1, $g_iStyle > 0 ? 0xFFEC00 : 0xFF0000)
GUICtrlSetFont(-1, 8, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")

$idPowerOff = GUICtrlCreateButton(-1, 20, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetState(-1, $g_bDisablePowerOff ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("SHUTDOWN"))

$idReboot = GUICtrlCreateButton(-1, 65, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -239)
GUICtrlSetState(-1, $g_bDisableReboot ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("REBOOT"))

$idLockSession = GUICtrlCreateButton(-1, 110, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -112)
GUICtrlSetState(-1, $g_bDisableLockSession ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("LOCK_SESSION"))

$idUnlock = GUICtrlCreateButton(-1, 290, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -177)
GUICtrlSetTip(-1, _getLang("UNLOCK"))

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Center and show window
WinMove($hPassGUI, "", (@DesktopWidth - $g_iWidthPassGUI) / 2, (@DesktopHeight - $g_iHeightPassGUI) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Detect key
Local $aAccelKeys = [ _
   ["{ENTER}", $idUnlock] _ ; Enter/Intro
]

GUISetAccelerators($aAccelKeys, $hPassGUI)

; Main loop
While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE, $idUnlock
         If _VerifyPassword() Then
            GUICtrlSetImage($idIcoPass, "imageres.dll", -102)
            GUISetBkColor(0x0F8600, $hGUI)	; semi dark green

            GUICtrlSetData($idTxtPass, _getLang("UNLOCKED"))
            GUICtrlSetColor($idTxtPass, $g_iStyle > 0 ? 0x0FFF00 : 0x0F9800) ; green/dark green

            GUICtrlSetData($idTxtMsg, "")

            If $g_iFailAttempts Then
               GUICtrlSetData($idErrorLabel, "")

			   _DisableButtons(True)
            EndIf

            ; Restore Windows Explorer if disabled
            If $g_bDisableExplorer Then _chkExplorer(False)

            SoundPlay(@WindowsDir & "\media\ding.wav", $SOUND_NOWAIT)

            Sleep(400)

            ExitLoop
         EndIf

         $g_iFailAttempts += 1

         GUICtrlSetData($idErrorLabel, _getLang("INCORRECT_PASSWORD", $g_iFailAttempts))
         GUICtrlSetData($idInput, "")

         GUICtrlSetImage($idIcoPass, "imageres.dll", -101)
         GUISetBkColor(0xC10000, $hGUI) ; semi dark red

		 SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

		 _DisableButtons(True)

		 If $g_iFailAttempts >= 3 Then Sleep(100 * $g_iFailAttempts)

		 Sleep(300)

		 _DisableButtons(False)

         GUICtrlSetImage($idIcoPass, "shell32.dll", -245)
         GUISetBkColor($g_iBkColorGUI, $hGUI)

		 GUICtrlSetState($idInput, $GUI_FOCUS)

      Case $idPowerOff
		 _ShutdownSys("/s")

      Case $idReboot
		 _ShutdownSys("/r")

	  Case $idLockSession
		 _DisableButtons(True)

		 If $g_bDisableExplorer Then _chkExplorer(False) ; We temporarily unlock... we avoid the black screen >=w8

		 DllCall("user32.dll", "int", "LockWorkStation")
		 Sleep(300)
		 _DisableButtons(False)

   EndSwitch

   ; check session...
   If _IsSessionLocked() Then
	  ; We temporarily release it if the user locks the session, preventing unwanted locks
	  _chkExplorer(False)
   Else
	  _chkExplorer(True)	; We activate it again
   EndIf

   Sleep(50)	; save CPU :?
WEnd

; ... exit
_chkUpdates()

Exit

;~ Functions
Func _IsSessionLocked()
   Static $iLastCheck, $bLastState = False

   ; Only check every X ms to reduce CPU usage
   If TimerDiff($iLastCheck) < 500 Then Return $bLastState

   $iLastCheck = TimerInit() ; reset timer

   $aResult = DllCall("user32.dll", "bool", "GetForegroundWindow")

   $bLastState = (Not @error And $aResult[0] = 0)

   Return $bLastState
EndFunc

Func _chkExplorer($bParam)
   Static $bLastParam

   If $bParam = $bLastParam Then Return

   $bLastParam = $bParam

   $aProcessList = ProcessList("explorer.exe")

   If Not @error Then
	  $sFunc = "Nt" & ($bParam ? "Suspend" : "Resume") & "Process"
	  For $i = 1 To $aProcessList[0][0]
		 $hProcess = _WinAPI_OpenProcess($PROCESS_SUSPEND_RESUME, False, $aProcessList[$i][1])

		 If $hProcess Then
			DllCall("ntdll.dll", "int", $sFunc, "ptr", $hProcess)
			_WinAPI_CloseHandle($hProcess)
		 EndIf
	  Next
   EndIf
EndFunc

Func _ShutdownSys($sParam = "")
   _DisableButtons(True)
   Run("cmd /c shutdown " & $sParam & " /f /t 0", "", @SW_HIDE)
EndFunc

Func _VerifyPassword()
   Return (_getHash(GUICtrlRead($idInput)) = $g_sPassHash)
EndFunc

Func _getHash($sInput)
   $sHash = _Crypt_HashData($sInput, 0x0000800e) ; sha512
   Return _Crypt_HashData($sHash, $CALG_MD5) ; 128-bit
EndFunc

Func _Time()
   $h24 = @HOUR
   $apm = "a"

   If $h24 >= 12 Then
      $apm = "p"
      If $h24 > 12 Then $h24 -= 12
   ElseIf $h24 = 0 Then
      $h24 = 12
   EndIf

   Return $h24 & ":" & @MIN & " " & $apm & "m"
EndFunc

Func _GenerateNewHash()
   $bValid = False
   $sInput = ""

   ; Loop until valid password is entered
   While Not $bValid
      $sInput = InputBox(_getLang("HASH_GENERATOR_TITLE"), _getLang("HASH_GENERATOR_MSG") & @CRLF & @CRLF & "- " & _getLang("MIN_CHARS", $g_iPassMinLength, $g_iPassMaxLength) & @CRLF & "- " & _getLang("NO_SPACES"), "", "*", 350)

      ; If user cancels
      If @error Then
         MsgBox($MB_ICONINFORMATION, _getLang("INFO"), _getLang("HASH_GENERATION_CANCELED"))
         Exit _chkExplorer(False)

      EndIf

      ; Validations
      If StringLen($sInput) < $g_iPassMinLength Or StringLen($sInput) > $g_iPassMaxLength Then
         MsgBox($MB_ICONWARNING, _getLang("ERROR_TITLE"), _getLang("MIN_CHARS_ERROR", $g_iPassMinLength,  $g_iPassMaxLength))
	  ElseIf StringIsSpace($sInput) Then
         MsgBox($MB_ICONWARNING, _getLang("ERROR_TITLE"), _getLang("SPACES_ONLY_ERROR"))
      ElseIf StringInStr($sInput, " ") Then
         MsgBox($MB_ICONWARNING, _getLang("ERROR_TITLE"), _getLang("SPACES_NOT_ALLOWED_ERROR"))
      Else
         $bValid = True
      EndIf
   WEnd

   ; Generate and display hash
   InputBox(_getLang("GENERATED_HASH_TITLE"), _getLang("GENERATED_HASH_MSG") & @CRLF & @CRLF & $sInput & @CRLF & @CRLF & _getLang("YOUR_NEW_HASH"), _getHash($sInput), "", 350)
EndFunc

Func _ProcessParameters()
   For $i = 1 To $CmdLine[0]
      Switch $CmdLine[$i]
         Case "/GenerateHash", "/gh"
            _GenerateNewHash()
            Exit _chkExplorer(False)

         Case "/PassHash", "/ph"
            If $i + 1 <= $CmdLine[0] Then
               $g_sPassHash = $CmdLine[$i + 1]
               $i += 1 ; Skip to next parameter

               ; Basic hash validation
               If StringLen($g_sPassHash) <> 34 Or StringLeft($g_sPassHash, 2) <> "0x" Then
                  MsgBox($MB_ICONERROR, _getLang("ERROR_TITLE"), _getLang("INVALID_HASH") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("GENERATE_HASH_HELP") & @CRLF & @CRLF & @ScriptName & " /GenerateHash")
				  Exit _chkExplorer(False)
               EndIf
            EndIf

         Case "/DisableExplorer", "/de"
            $g_bDisableExplorer = True
			_chkExplorer($g_bDisableExplorer)

         Case "/DisablePowerOff", "/dp"
            $g_bDisablePowerOff = True

         Case "/DisableReboot", "/dr"
            $g_bDisableReboot = True

		 Case "/DisableLockSession", "/dl"
			$g_bDisableLockSession = True

         Case "/Style", "/st"
            If $i + 1 <= $CmdLine[0] Then
               $g_iStyle = $CmdLine[$i + 1]
               $i += 1

               Switch $g_iStyle
                  Case "1"   ; dark
                     $g_iBkColorPassGUI = 0x050505
                  Case "2"   ; aqua
                     $g_iBkColorPassGUI = 0x00696D
               EndSwitch
            EndIf

		 Case "/AutoUpdater", "/au"
			AdlibRegister("_chkUpdatesAsync", 500)

      EndSwitch
   Next

   If $g_sPassHash = "" Then
      $iButton = MsgBox($MB_YESNO, _getLang("ERROR_TITLE"), _getLang("MISSING_HASH") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("GENERATE_HASH_HELP") & @CRLF & @CRLF & @ScriptName & " /GenerateHash" & @CRLF & @CRLF & @CRLF & _getLang("GENERATE_NOW"))

      If $iButton = $IDYES Then _GenerateNewHash()

      Exit _chkExplorer(False)

   EndIf

   ; save button parameters
   Local $aButtons = [$g_bDisablePowerOff, $g_bDisableReboot, $g_bDisableLockSession]

   For $i = 0 To UBound($aButtons) - 1
	  $g_aButtonsParam[$i] = $aButtons[$i]
   Next
EndFunc

Func _LoadLanguage()
   $sLangFile = @ScriptDir & "\lang\" & $g_sLanguage & ".ini"

   ; If the language file does not exist, load English by default.
   If Not FileExists($sLangFile) Then $sLangFile = @ScriptDir & "\lang\en.ini"
   If Not FileExists($sLangFile) Then Exit MsgBox($MB_ICONERROR, "Error", "Language file not found")

   ; Read file
   $hFile = FileOpen($sLangFile, $FO_UTF8_NOBOM + $FO_READ)
   If $hFile = -1 Then Exit MsgBox($MB_ICONERROR, "Error", "Unable to open language file")
   $sContent = FileRead($hFile)
   FileClose($hFile)

   ; Process lines
   $aLines = StringSplit(StringStripCR($sContent), @LF)
   $bInSection = False

   For $i = 1 To $aLines[0]
	  $sLine = StringStripWS($aLines[$i], $STR_STRIPLEADING + $STR_STRIPTRAILING)

	  ; Ignore empty lines or comments
	  If $sLine = "" Or StringLeft($sLine, 1) = ";" Then ContinueLoop

	  ; Check if it is a section (case-insensitive)
	  If StringLeft($sLine, 1) = "[" And StringRight($sLine, 1) = "]" Then
		 $sSectionName = StringMid($sLine, 2, StringLen($sLine) - 2)
		 $bInSection = (StringLower($sSectionName) = StringLower($g_sLanguage))
		 ContinueLoop
	  EndIf

	  ; Process key=value if it is in the correct section
	  If $bInSection Then
		 $iPos = StringInStr($sLine, "=")
		 If $iPos > 0 Then
			; Get key and value
			$sKey = StringStripWS(StringLeft($sLine, $iPos - 1), $STR_STRIPLEADING + $STR_STRIPTRAILING)
			$sValue = StringStripWS(StringMid($sLine, $iPos + 1), $STR_STRIPLEADING + $STR_STRIPTRAILING)

			; Convert key to uppercase if not already
			If Not StringIsUpper($sKey) Then $sKey = StringUpper($sKey)

			; Save to dictionary (always in capital letters)
			$g_oLangLookup.Item($sKey) = $sValue
		 EndIf
	  EndIf
   Next
EndFunc

Func _getLang($sKey, $vParams = "", $vB = "", $vC = "", $vD = "")
   ; Check if the key exists
   $sText = $g_oLangLookup.Item($sKey)

   If @error Then Return "NOT FOUND: [" & $sKey & "]"

   ; Process dynamic parameters
   If $vParams <> "" Then Return StringFormat($sText, $vParams, $vB, $vC, $vD)

   Return $sText
EndFunc

Func _getOSLang()
   ; supported languages
   Local $aLanguageMap[][2] = [ _
	  ["0436", "af"], _  ; Afrikaans
	  ["045E", "am"], _  ; Amharic
	  ["0401", "ar"], ["0801", "ar"], ["0C01", "ar"], ["1001", "ar"], ["1401", "ar"], ["1801", "ar"], ["1C01", "ar"], ["2001", "ar"], ["2401", "ar"], ["2801", "ar"], ["2C01", "ar"], ["3001", "ar"], ["3401", "ar"], ["3801", "ar"], ["3C01", "ar"], ["4001", "ar"], _  ; Arabic (regional variants)
	  ["042B", "hy"], _  ; Armenian
	  ["042C", "az"], ["082C", "az"], _  ; Azerbaijani
	  ["044D", "as"], _  ; Assamese
	  ["0423", "be"], _  ; Belarusian
	  ["0445", "bn"], ["0845", "bn"], _  ; Bengali
	  ["0402", "bg"], _  ; Bulgarian
	  ["0455", "my"], _  ; Burmese
	  ["0403", "ca"], ["0803", "ca"], _  ; Catalan
	  ["0004", "zh"], ["0804", "zh"], ["0C04", "zh"], ["1004", "zh"], ["1404", "zh"], ["0404", "zh"], ["7C04", "zh"], _  ; Chinese (variants)
	  ["041A", "hr"], ["101A", "hr"], _  ; Croatian
	  ["0405", "cs"], _  ; Czech
	  ["0406", "da"], _  ; Danish
	  ["048C", "prs"], _  ; Dari
	  ["0465", "dv"], _  ; Divehi
	  ["0413", "nl"], ["0813", "nl"], _  ; Dutch
	  ["0409", "en"], ["0809", "en"], ["0C09", "en"], ["1009", "en"], ["1409", "en"], ["1809", "en"], ["1C09", "en"], ["2009", "en"], ["2409", "en"], ["2809", "en"], ["2C09", "en"], ["3009", "en"], ["3409", "en"], ["4009", "en"], ["4409", "en"], ["4809", "en"], _  ; English (regional variants)
	  ["0425", "et"], _  ; Estonian
	  ["0463", "ps"], _  ; Pashto
	  ["040B", "fi"], _  ; Finnish
	  ["040C", "fr"], ["080C", "fr"], ["0C0C", "fr"], ["100C", "fr"], ["140C", "fr"], ["180C", "fr"], _  ; French (regional variants)
	  ["0462", "fy"], _  ; Frisian
	  ["0456", "gl"], _  ; Galician
	  ["0457", "kok"], _  ; Konkani
	  ["0407", "de"], ["0807", "de"], ["0C07", "de"], ["1007", "de"], ["1407", "de"], _  ; German (regional variants)
	  ["0408", "el"], _  ; Greek
	  ["046F", "kl"], _  ; Greenlandic
	  ["0447", "gu"], _  ; Gujarati
	  ["040D", "he"], _  ; Hebrew
	  ["0439", "hi"], _  ; Hindi
	  ["040E", "hu"], _  ; Hungarian
	  ["040F", "is"], _  ; Icelandic
	  ["0421", "id"], _  ; Indonesian
	  ["0470", "ig"], _  ; Igbo
	  ["0410", "it"], ["0810", "it"], _  ; Italian
	  ["0411", "ja"], _  ; Japanese
	  ["044B", "kn"], _  ; Kannada
	  ["043F", "kk"], _  ; Kazakh
	  ["0451", "bo"], _  ; Tibetan
	  ["0412", "ko"], _  ; Korean
	  ["0492", "ku"], _  ; Kurdish
	  ["0440", "ky"], _  ; Kyrgyz
	  ["0426", "lv"], _  ; Latvian
	  ["0427", "lt"], _  ; Lithuanian
	  ["042E", "hsb"], ["082E", "dsb"], _  ; Upper Sorbian, Lower Sorbian
	  ["0430", "tn"], ["0432", "tn"], ["0832", "tn"], _  ; Setswana/Tswana
	  ["0434", "zu"], ["0435", "zu"], _  ; Zulu
	  ["042F", "mk"], _  ; Macedonian
	  ["044C", "ml"], _  ; Malayalam
	  ["043A", "mt"], _  ; Maltese
	  ["0458", "mni"], _  ; Manipuri
	  ["0450", "mn"], ["0850", "mn"], _  ; Mongolian
	  ["043E", "ms"], ["083E", "ms"], _  ; Malay
	  ["044E", "mr"], _  ; Marathi
	  ["0475", "haw"], _  ; Hawaiian
	  ["0414", "no"], ["0814", "no"], _  ; Norwegian
	  ["0448", "or"], _  ; Odia
	  ["0461", "ne"], _  ; Nepali
	  ["0415", "pl"], _  ; Polish
	  ["0416", "pt"], ["0816", "pt"], _  ; Portuguese
	  ["0446", "pa"], _  ; Punjabi
	  ["046B", "quz"], ["086B", "quz"], ["0C6B", "quz"], _  ; Quechua
	  ["0418", "ro"], _  ; Romanian
	  ["0419", "ru"], _  ; Russian
	  ["0487", "rw"], _  ; Kinyarwanda
	  ["044F", "sa"], _  ; Sanskrit
	  ["043B", "se"], ["083B", "se"], ["0C3B", "se"], _  ; Northern Sami
	  ["081A", "sr"], ["041A", "sr"], ["101A", "sr"], _  ; Serbian
	  ["0459", "sd"], ["0859", "sd"], _  ; Sindhi
	  ["041D", "sv"], ["081D", "sv"], _  ; Swedish
	  ["045B", "si"], _  ; Sinhala
	  ["0424", "sl"], _  ; Slovenian
	  ["041B", "sk"], _  ; Slovak
	  ["043C", "gd"], ["0491", "gd"], _  ; Scottish Gaelic
	  ["040A", "es"], ["080A", "es"], ["0C0A", "es"], ["100A", "es"], ["140A", "es"], ["180A", "es"], ["1C0A", "es"], ["200A", "es"], ["240A", "es"], ["280A", "es"], ["2C0A", "es"], ["300A", "es"], ["340A", "es"], ["380A", "es"], ["3C0A", "es"], ["400A", "es"], ["440A", "es"], ["480A", "es"], ["4C0A", "es"], ["500A", "es"], ["540A", "es"], _  ; Spanish (regional variants)
	  ["0441", "sw"], _  ; Swahili
	  ["041E", "th"], _  ; Thai
	  ["0437", "ka"], _  ; Georgian
	  ["045A", "syr"], _  ; Syriac
	  ["0449", "ta"], ["0849", "ta"], _  ; Tamil
	  ["044A", "te"], _  ; Telugu
	  ["041F", "tr"], _  ; Turkish
	  ["0444", "tt"], _  ; Tatar
	  ["045F", "tzm"], ["085F", "tzm"], ["105F", "tzm"], _  ; Tamazight
	  ["0422", "uk"], _  ; Ukrainian
	  ["0420", "ur"], ["0820", "ur"], _  ; Urdu
	  ["0443", "uz"], ["0843", "uz"], _  ; Uzbek
	  ["042A", "vi"], _  ; Vietnamese
	  ["0452", "cy"], _  ; Welsh
	  ["046A", "yo"]]   ; Yoruba

   $sLangCode = @OSLang		; Get language code

   ; Find the language code in the table
   For $i = 0 To UBound($aLanguageMap) - 1
	  If $aLanguageMap[$i][0] = $sLangCode Then Return $aLanguageMap[$i][1]
   Next

   ; If not found, return English by default
   Return "en"
EndFunc

Func _EnableBlur($hGUI)
   If Not StringRegExp(@OSVersion, "_(8|10|11|201|202)") Then	; Get OS Version
	  WinSetTrans($hGUI, "", $g_iTransparencyGUI)
	  Return False
   EndIf

   Const $ACCENT_ENABLE_BLURBEHIND = 3

   $tAccentPolicy = DllStructCreate("int AccentState; int AccentFlags; int GradientColor; int AnimationId")
   DllStructSetData($tAccentPolicy, "AccentState", $ACCENT_ENABLE_BLURBEHIND)

   Const $WCA_ACCENT_POLICY = 19

   $tWindowCompositionAttributeData = DllStructCreate("dword Attribute; ptr Data; ulong DataSize")
   DllStructSetData($tWindowCompositionAttributeData, "Attribute", $WCA_ACCENT_POLICY)
   DllStructSetData($tWindowCompositionAttributeData, "Data", DllStructGetPtr($tAccentPolicy))
   DllStructSetData($tWindowCompositionAttributeData, "DataSize", DllStructGetSize($tAccentPolicy))

   $aRet = DllCall("user32.dll", "int", "SetWindowCompositionAttribute", "hwnd", $hGUI, "ptr", DllStructGetPtr($tWindowCompositionAttributeData))

   If @error Or Not $aRet[0] Then Return False

   Return True
EndFunc

Func _DisableButtons($bValue)
   Local $aButtons = [$idPowerOff, $idReboot, $idLockSession, $idUnlock]

   For $i = 0 To UBound($aButtons) - 1
	  ; get button parameters
	  If Not $g_aButtonsParam[$i] Then GUICtrlSetState($aButtons[$i], $bValue ? $GUI_DISABLE : $GUI_ENABLE)
   Next
EndFunc

; upd
Func _chkUpdatesAsync()
   AdlibUnRegister("_chkUpdatesAsync")
   _chkUpdates()
EndFunc

Func _chkUpdates()
   Static $iReview

   $iReview += 1

   ; Handle file replacement if this is the second call
   If $iReview > 1 Then
	  $sExeNew = @ScriptName & ".new"
      If FileExists($sExeNew) Then Run("cmd /c ping -n 2 localhost >nul & move /y " & $sExeNew & " " & @ScriptName, "", @SW_HIDE)

      Return
   EndIf

   ; Initialize update check
   $sReleasesURL = "https://api.github.com/repos/mlibre2/" & $g_sName & $g_sComp & "/releases/latest"

   _Log(_getLang("START_CHECK_NEW_UPDATE"))
   _Log(_getLang("CURRENT_VERSION", $g_sVersion))

   ; Check internet connection
   If Not _IsInternetConnected() Then
      _Log("Error: " & _getLang("ERROR_NO_INTERNET"))
      Return
   EndIf

   ; Get release information
   $sResponse = BinaryToString(InetRead($sReleasesURL))
   If @error Or $sResponse = "" Then
      _Log("Error: " & _getLang("ERROR_NO_GET_UPDATE"))
      Return
   EndIf

   ; Parse version
   $aVersionMatch = StringRegExp($sResponse, '"tag_name":"v?([\d.]+)"', 1)
   If @error Or Not IsArray($aVersionMatch) Then
      _Log("Error: " & _getLang("ERROR_INVALID_VERSION"))
      Return
   EndIf

   $sLatestVersion = $aVersionMatch[0]
   _Log(_getLang("LATEST_VERSION", $sLatestVersion))

   ; Compare versions
   If _VersionCompare($g_sVersion, $sLatestVersion) >= 0 Then
      _Log(_getLang("ALREADY_LATEST_VERSION"))
      Return
   EndIf

   ; Get download URL
   $aUrlMatch = StringRegExp($sResponse, '"browser_download_url":"(https:[^"]+?' & $g_sName & '[^"]+?\.zip)"', 1)
   If @error Or Not IsArray($aUrlMatch) Then
      _Log("Error: " & _getLang("ERROR_DOWNLOAD_URL"))
      Return
   EndIf

   $sDownloadURL = StringReplace($aUrlMatch[0], "\/", "/")
   _Log(_getLang("DOWNLOAD_URL", $sDownloadURL))

   ; Prepare download
   $sUpdateTempDir = @ScriptDir & "\" & $g_sName & "Update\"

   If Not DirCreate($sUpdateTempDir) Then
      _Log("Error: " & _getLang("ERROR_CREATE_TMP_DIR"))
      Return
   EndIf

   $sZipFile = $sUpdateTempDir & $g_sName & $sLatestVersion & ".zip"

   ; Download with progress
   $hDownload = InetGet($sDownloadURL, $sZipFile, $INET_FORCEBYPASS, $INET_DOWNLOADBACKGROUND)
   If @error Then
      _Log("Error: " & _getLang("ERROR_DOWNLOAD"))
	  DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf

   $iProgressWidth = 400  ; Width of the progress window
   $iProgressHeight = 100 ; Progress window height
   $iPosX = @DesktopWidth - $iProgressWidth + 60  ; right margin px
   $iPosY = @DesktopHeight - $iProgressHeight - 60 ; margin-bottom px

   ProgressOn(_getLang("DOWNLOADING_UPDATE", $sLatestVersion), _getLang("GETTING_FILES"), "0%", $iPosX, $iPosY, $DLG_MOVEABLE)

   $iLastPercent = 0
   $iFileSize = 0
   $iStartTime = TimerInit()

   ; Download progress loop
   Do
      Sleep(50)
	  $iBytes = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
      $iFileSize = InetGetInfo($hDownload, $INET_DOWNLOADSIZE)

      If $iFileSize > 0 Then
		 $iPercent = ($iBytes / $iFileSize) * 100
         $iPercent = $iPercent > 100 ? 100 : $iPercent

         If $iPercent <> $iLastPercent Then
            $iLastPercent = $iPercent
			$iElapsed = TimerDiff($iStartTime) / 1000
			$sSpeed = $iElapsed > 0 ? _BytesToSize($iBytes / $iElapsed) & "/s" : "N/A"

            ProgressSet($iPercent, Round($iPercent) & "% - " & _BytesToSize($iBytes) & "/" & _BytesToSize($iFileSize) & @CRLF & _getLang("SPEED") & ": " & $sSpeed)
         EndIf
      EndIf
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)

   InetClose($hDownload)
   ProgressSet(100, "100% - " & _getLang("DONE") & " " & _BytesToSize($iFileSize), _getLang("COMPLETE"))
   Sleep(2000)
   ProgressOff()

   ; Verify download
   If Not FileExists($sZipFile) Or FileGetSize($sZipFile) = 0 Then
      _Log("Error: " & _getLang("ERROR_DOWNLOAD"))
      DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf

   ; Extract files
   $oShell = ObjCreate("Shell.Application")
   If Not IsObj($oShell) Then
      _Log("Error: " & _getLang("ERROR_EXTRACT_FILES"))
      DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf

   $oZip = $oShell.NameSpace($sZipFile)
   $oDest = $oShell.NameSpace($sUpdateTempDir)

   If Not IsObj($oZip) Or Not IsObj($oDest) Then
      _Log("Error: " & _getLang("ERROR_EXTRACT_FILES"))
      DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf

   $oDest.CopyHere($oZip.Items(), 0x14) ; 16 (no dialog) + 4 (yes to all)
   Sleep(1000) ; Wait for operation

   ; Verify extracted files
   $bExeNewExists = FileExists($sUpdateTempDir & @ScriptName)
   $bLangExists = FileExists($sUpdateTempDir & "lang\")

   If Not $bExeNewExists Or Not $bLangExists Then
      _Log("Error: " & _getLang("ERROR_NO_VALID_FILES"))
      DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf

   ; Move new executable
   If Not FileCopy($sUpdateTempDir & @ScriptName, @ScriptDir & "\" & @ScriptName & ".new", $FC_OVERWRITE) Then
      _Log("Error: " & _getLang("ERROR_COPY_NEW_FILE", @ScriptName))
      DirRemove($sUpdateTempDir, $DIR_REMOVE)
      Return
   EndIf
   _Log(_getLang("COPY_NEW_FILE", @ScriptName))

   ; Move language files if they exist
   If Not DirCopy($sUpdateTempDir & "lang\", @ScriptDir & "\lang\", $FC_OVERWRITE) Then
	  _Log("Error: " & _getLang("ERROR_COPY_NEW_LANG"))
	  Return
   EndIf
   _Log(_getLang("COPY_NEW_LANG"))

   ; Cleanup
   DirRemove($sUpdateTempDir, $DIR_REMOVE)
   _Log(_getLang("UPDATE_PREPARED"))

   MsgBox(BitOR($MB_ICONINFORMATION, $MB_TOPMOST), _getLang("MSG1_DOWNLOADED", $g_sName, $sLatestVersion), _getLang("MSG2_DOWNLOADED"), 3)
EndFunc

; Helper functions
Func _IsInternetConnected()
   $aReturn = DllCall("connect.dll", "long", "IsInternetConnected")
   Return Not @error And $aReturn[0] = 0
EndFunc

Func _BytesToSize($iBytes)
   Return StringFormat("%.2f MB", $iBytes / (1024 * 1024))
EndFunc

Func _Log($sMessage)
   Static $sLogPath = @ScriptDir & "\" & $g_sName & "Debug.log"
   Static $sLastDateTime = "", $iLastSec = -1
   $iCurrentSec = @SEC

   If $iCurrentSec <> $iLastSec Then
	  $sLastDateTime = "[" & @MDAY & "/" & @MON & "/" & @YEAR & " - " & @HOUR & ":" & @MIN & ":" & $iCurrentSec & "]"
	  $iLastSec = $iCurrentSec
   EndIf

   $hFile = FileOpen($sLogPath, $FO_APPEND + $FO_UTF8_NOBOM)
   FileWriteLine($hFile, $sLastDateTime & " " & $sMessage)

   ; Check if the message contains the word "error" (case insensitive)
   If StringInStr($sMessage, "error", $STR_NOCASESENSE) Then FileWriteLine($hFile, $sLastDateTime & " " & _getLang("REPORT", "https://github.com/mlibre2/" & $g_sName & $g_sComp & "/issues"))

   FileClose($hFile)
EndFunc
