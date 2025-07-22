#pragma compile(FileDescription, Login secondary lock screen Windows)
#pragma compile(ProductName, myLogin)
#pragma compile(ProductVersion, 1.9)
#pragma compile(LegalCopyright, © by mlibre2)
#pragma compile(FileVersion, 1.9)
#pragma compile(Icon, 'C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Threat.contrast-white.ico')

Const $g_sVersion = "1.9"

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
#include <WinAPIGdi.au3>

; configuration
$g_sPassHash = ""
Const $g_iTransparencyGUI = 150						; 0-255 (transparent-opaque) fullscreen
Const $g_iTransparencyPassGUI = 180					; 0-255 (transparent-opaque) for window
$g_iColorTxt = 0xFFFFFF								; Text color
Const $g_iBkColorGUI = 0x000000						; Background color (full)
$g_iBkColorPassGUI = 0xFFFFFF						; Background color (window)
Const $g_iWidthPassGUI = 350						; Window width
Const $g_iHeightPassGUI = 195						; Window height
$g_iFailAttempts = 0								; Failed attempts (login)
$g_iStyle = 0										; Color style (0=white/1=dark/2=aqua)
$g_bDisableExplorer = False							; Disable Windows Explorer
$g_bDisableTaskMgr = False							; Disable Task Manager
$g_bDisablePowerOff = False							; Disable system Shutdown button
$g_bDisableReboot = False							; Disable system Reboot button
Const $g_sLanguage = _getOSLang()					; Get language (system)
$g_oLangLookup = ObjCreate("Scripting.Dictionary")	; Optimize searches table hash O(1)
Const $g_iPassMinLength = 2							; Define minimum password length
Const $g_iPassMaxLength = 30						; Define maximum password length
Const $g_sExplorer = "explorer.exe"					;
$g_bProcessExists = False							; Check if a process exists

; Load language files
_LoadLanguage()

;~ Check single instance prevent double execution
If Not _Singleton("ScreenLockWindow", 1) Then
   MsgBox($MB_ICONWARNING, @ScriptName, _getLang("program_already_open"), 3)
   Exit
EndIf

;~ Check Explorer
_chkExplorer()

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
$idIcoPass = GUICtrlCreateIcon("shell32.dll", -245, ($g_iWidthPassGUI - 32) / 2, 10, 32, 32)
GUICtrlSetTip(-1, _getLang("restricted_access"))

$idTxtPass = GUICtrlCreateLabel(_getLang("system_locked"), 10, 45, $g_iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 12, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

$idTxtMsg = GUICtrlCreateLabel(_getLang("enter_password"), 10, 65, $g_iWidthPassGUI - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

$idInput = GUICtrlCreateInput("", 50, 90, $g_iWidthPassGUI - 100, 20, $ES_PASSWORD + $ES_CENTER)
GUICtrlSetState(-1, $GUI_FOCUS)

$idErrorLabel = GUICtrlCreateLabel("", 10, 120, $g_iWidthPassGUI - 20, 20, $SS_CENTER)
GUICtrlSetColor(-1, $g_iStyle > 0 ? 0xFFEC00 : 0xFF0000)
GUICtrlSetFont(-1, 8, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")

$idUnlock = GUICtrlCreateButton(-1, 290, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -177)
GUICtrlSetTip(-1, _getLang("unlock"))

$idPowerOff = GUICtrlCreateButton(-1, 20, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetState(-1, $g_bDisablePowerOff ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("shutdown"))

$idReboot = GUICtrlCreateButton(-1, 65, 146, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -239)
GUICtrlSetState(-1, $g_bDisableReboot ? $GUI_DISABLE : $GUI_ENABLE)
GUICtrlSetTip(-1, _getLang("reboot"))

GUICtrlCreateLabel(_getLang("start_time") & " " & _Time(), 130, 160, 120)
GUICtrlSetFont(-1, 8, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

GUICtrlCreateLabel("MyLogin v" & $g_sVersion, 295, 5)
GUICtrlSetFont(-1, 6, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $g_iStyle > 0 ? $g_iColorTxt : 0x000000)

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Center and show window
WinMove($hPassGUI, "", (@DesktopWidth - $g_iWidthPassGUI) / 2, (@DesktopHeight - $g_iHeightPassGUI) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Block special keys
Local $aHotKeys = [ _
   "{F4}","{DEL}","{TAB}","{HOME}","{ESC}","{UP}","{DOWN}","{LEFT}","{RIGHT}","{SPACE}", _
   "+{SPACE}", _	; Shift+Space
   "^{SPACE}" _		; Ctrl+Space
]

For $i = 0 To UBound($aHotKeys) - 1
   HotKeySet($aHotKeys[$i], "_BlockKeys")
Next

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

            GUICtrlSetData($idTxtPass, _getLang("unlocked"))
            GUICtrlSetColor($idTxtPass, $g_iStyle > 0 ? 0x0FFF00 : 0x0F9800) ; green/dark green

            GUICtrlSetData($idTxtMsg, "")

            If $g_iFailAttempts > 0 Then
               GUICtrlSetData($idErrorLabel, "")
            EndIf

            ; Restore Windows Explorer if disabled
            If $g_bDisableExplorer Then
               Run($g_sExplorer, @WindowsDir, @SW_HIDE)
            EndIf

            ; Restore Task Manager if disabled
            If $g_bDisableTaskMgr Then
               RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "0")
            EndIf

			_DisableButtons()

            SoundPlay(@WindowsDir & "\media\ding.wav", $SOUND_NOWAIT)

            Sleep(400)

            ExitLoop
         EndIf

         $g_iFailAttempts += 1

         GUICtrlSetData($idErrorLabel, _getLang("incorrect_password", $g_iFailAttempts))
         GUICtrlSetData($idInput, "")
         GUICtrlSetState($idInput, $GUI_FOCUS)

         SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

         GUICtrlSetImage($idIcoPass, "imageres.dll", -101)
         GUISetBkColor(0xC10000, $hGUI) ; semi dark red

         Sleep(300)

         GUICtrlSetImage($idIcoPass, "shell32.dll", -245)
         GUISetBkColor($g_iBkColorGUI, $hGUI)

      Case $idPowerOff
		 _DisableButtons()
         Run("cmd /c shutdown /s /f /t 0", "", @SW_HIDE)

      Case $idReboot
		 _DisableButtons()
         Run("cmd /c shutdown /r /f /t 0", "", @SW_HIDE)

   EndSwitch

WEnd

; Cleanup and exit
Exit

;~ Functions
Func _chkExplorer()
   $g_bProcessExists = ProcessExists($g_sExplorer) > 0

   If $g_bDisableExplorer And $g_bProcessExists Then
	  Run("cmd /c taskkill /f /im " & $g_sExplorer, "", @SW_HIDE)

   ElseIf Not $g_bProcessExists Then
	  ; Read Shell key value
	  $sRegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	  $sRegValue = "Shell"
	  $sShellValue = RegRead($sRegPath, $sRegValue)

	  If Not StringInStr($sShellValue, $g_sExplorer) > 0 Then
		 RegWrite($sRegPath, $sRegValue, "REG_SZ", $g_sExplorer)

		 MsgBox($MB_ICONWARNING, _getLang("explorer_error_title"), _getLang("explorer_error_msg") & @CRLF & @CRLF & $sRegValue & " " & _getLang("from_winlogon") & ": " & @CRLF & @CRLF & $sShellValue & @CRLF & @CRLF & _getLang("explorer_fix_msg"))

		 Run("cmd /c shutdown /r /f /t 0", "", @SW_HIDE)
		 Exit
	  Else
		 $g_bDisableExplorer = True
	  EndIf
   EndIf
EndFunc

Func _VerifyPassword()
   Return (_getHash(GUICtrlRead($idInput)) = $g_sPassHash)
EndFunc

Func _BlockKeys()
   SoundPlay(@WindowsDir & "\media\Windows Hardware Fail.wav", $SOUND_NOWAIT)
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
      $sInput = InputBox(_getLang("hash_generator_title"), _getLang("hash_generator_msg") & @CRLF & @CRLF & "- " & _getLang("min_chars", $g_iPassMinLength & "|" & $g_iPassMaxLength) & @CRLF & "- " & _getLang("no_spaces"), "", "*", 350)

      ; If user cancels
      If @error Then
         MsgBox($MB_ICONINFORMATION, _getLang("info"), _getLang("hash_generation_canceled"))
         If $g_bProcessExists Then Exit

      EndIf

      ; Validations
      If StringLen($sInput) < $g_iPassMinLength Or StringLen($sInput) > $g_iPassMaxLength Then
         MsgBox($MB_ICONWARNING, _getLang("error_title"), _getLang("min_chars_error", $g_iPassMinLength & "|" & $g_iPassMaxLength))
	  ElseIf StringIsSpace($sInput) Then
         MsgBox($MB_ICONWARNING, _getLang("error_title"), _getLang("spaces_only_error"))
      ElseIf StringInStr($sInput, " ") Then
         MsgBox($MB_ICONWARNING, _getLang("error_title"), _getLang("spaces_not_allowed_error"))
      Else
         $bValid = True
      EndIf
   WEnd

   ; Generate and display hash
   InputBox(_getLang("generated_hash_title"), _getLang("generated_hash_msg") & @CRLF & @CRLF & $sInput & @CRLF & @CRLF & _getLang("your_new_hash"), _getHash($sInput), "", 350)
EndFunc

Func _ProcessParameters()
   For $i = 1 To $CmdLine[0]
      Switch $CmdLine[$i]
         Case "/GenerateHash", "/gh"
            _GenerateNewHash()
            If $g_bProcessExists Then Exit

         Case "/PassHash", "/ph"
            If $i + 1 <= $CmdLine[0] Then
               $g_sPassHash = $CmdLine[$i + 1]
               $i += 1 ; Skip to next parameter

               ; Basic hash validation
               If StringLen($g_sPassHash) <> 34 Or StringLeft($g_sPassHash, 2) <> "0x" Then
                  MsgBox($MB_ICONERROR, _getLang("error_title"), _getLang("invalid_hash") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("generate_hash_help") & @CRLF & @CRLF & @ScriptName & " /GenerateHash")
                  If $g_bProcessExists Then Exit
               EndIf
            EndIf

         Case "/DisableTaskMgr", "/dt"
            $g_bDisableTaskMgr = True
			RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "1")

         Case "/DisableExplorer", "/de"
            $g_bDisableExplorer = True

         Case "/DisablePowerOff", "/dp"
            $g_bDisablePowerOff = True

         Case "/DisableReboot", "/dr"
            $g_bDisableReboot = True

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

      EndSwitch
   Next

   If $g_sPassHash = "" Then
      $iButton = MsgBox($MB_YESNO, _getLang("error_title"), _getLang("missing_hash") & @CRLF & @CRLF & @ScriptName & " /PassHash 0x9461E4B1394C6134483668F09CCF7B93" & @CRLF & @CRLF & _getLang("generate_hash_help") & @CRLF & @CRLF & @ScriptName & " /GenerateHash" & @CRLF & @CRLF & @CRLF & _getLang("generate_now"))

      If $iButton = $IDYES Then _GenerateNewHash()

      If $g_bProcessExists Then Exit

   EndIf
EndFunc

Func _LoadLanguage()
   $sLangFile = @ScriptDir & "\lang\" & $g_sLanguage & ".ini"

   If Not FileExists($sLangFile) Then $sLangFile = @ScriptDir & "\lang\en.ini"
   If Not FileExists($sLangFile) Then Exit MsgBox(0x10, "Error", "Language file not found")

   $hFile = FileOpen($sLangFile, 256 + 128) ; $FO_UTF8_NOBOM + $FO_READ

   If $hFile = -1 Then Exit MsgBox(0x10, "Error", "Unable to open language file")

   $sContent = FileRead($hFile)

   FileClose($hFile)

   $aLines = StringSplit(StringStripCR($sContent), @LF)
   $bInSection = False

   For $i = 1 To $aLines[0]
	  $sLine = StringStripWS($aLines[$i], 3)

	  If $sLine = "" Or StringLeft($sLine, 1) = ";" Then ContinueLoop

	  If StringLeft($sLine, 1) = "[" And StringRight($sLine, 1) = "]" Then
		 $bInSection = (StringMid($sLine, 2, StringLen($sLine)-2) = $g_sLanguage)
		 ContinueLoop

	  EndIf

	  If $bInSection Then
			$iPos = StringInStr($sLine, "=")
            If $iPos > 0 Then
			   $g_oLangLookup.Item(StringStripWS(StringLeft($sLine, $iPos-1), 3)) = StringStripWS(StringMid($sLine, $iPos+1), 3)
            EndIf
	  EndIf

   Next
EndFunc

Func _getLang($sKey, $vParams = "")
   ; Check if the key exists
   If Not $g_oLangLookup.Exists($sKey) Then
	  Return "NOT FOUND: [" & $sKey & "]"
   EndIf

   $sText = $g_oLangLookup.Item($sKey)

   ; Process dynamic parameters
   If $vParams <> "" Then
	  $aParams = StringSplit($vParams, "|", 2)

	  For $i = 0 To UBound($aParams) - 1
		 $sText = StringReplace($sText, "%d", $aParams[$i], 1)
	  Next
   EndIf

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
	  If $aLanguageMap[$i][0] = $sLangCode Then
		 Return $aLanguageMap[$i][1]
	  EndIf
   Next

   ; If not found, return English by default
   Return "en"
EndFunc

Func _EnableBlur($hGUI)
   If Not StringRegExp(@OSVersion, "_(8|10|11|201|202)") Then	; Get OS Version
	  WinSetTrans($hGUI, "", $g_iTransparencyGUI)
	  Return False
   EndIf

   $tAccentPolicy = DllStructCreate("int AccentState; int AccentFlags; int GradientColor; int AnimationId")
   DllStructSetData($tAccentPolicy, "AccentState", 3)  ; ACCENT_ENABLE_BLURBEHIND

   $tWindowCompositionAttributeData = DllStructCreate("dword Attribute; ptr Data; ulong DataSize")
   DllStructSetData($tWindowCompositionAttributeData, "Attribute", 19)  ; WCA_ACCENT_POLICY
   DllStructSetData($tWindowCompositionAttributeData, "Data", DllStructGetPtr($tAccentPolicy))
   DllStructSetData($tWindowCompositionAttributeData, "DataSize", DllStructGetSize($tAccentPolicy))

   $aRet = DllCall("user32.dll", "int", "SetWindowCompositionAttribute", "hwnd", $hGUI, "ptr", DllStructGetPtr($tWindowCompositionAttributeData))

   If @error Or Not $aRet[0] Then Return False

   Return True
EndFunc

Func _DisableButtons()
   GUICtrlSetState($idPowerOff, $GUI_DISABLE)
   GUICtrlSetState($idReboot, $GUI_DISABLE)
   GUICtrlSetState($idUnlock, $GUI_DISABLE)
EndFunc
