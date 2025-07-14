#pragma compile(FileDescription, Login segundario para bloquear/desbloquear pantalla)
#pragma compile(ProductName, myLogin)
#pragma compile(ProductVersion, 1.3)
#pragma compile(LegalCopyright, © by mlibre2)
#pragma compile(FileVersion, 1.3)
#pragma compile(Icon, 'C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Threat.contrast-white.ico')

Global $sVersion = "1.3"

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

; Configuración global
Global $sPasswordCorrecta = ""
Global $iTransparencia = 150       	; 0-255 (transparente-opaco)
Global $iTransparenciaPassGUI = 180	; 0-255 (transparente-opaco) para ventana
Global $iColorTxt = 0xFFFFFF		; Color del texto
Global $iBkColor = 0x000000     	; Color de fondo (full)
Global $iBkColorPanel = 0xFFFFFF	; Color de fondo (ventana)
Global $iAnchoPass = 350           	; Ancho ventana
Global $iAltoPass = 200            	; Alto ventana
Global $iFail = 0					; Intentos fallidos (login)
Global $iStyle = 0					; Estilo de colores (0=blanco/1=dark(oscuro)/2=aqua)
Global $bDisableExplorer = False	; Deshabilitar el Windows Explorer
Global $bDisableTaskMgr = False		; Deshabilitar el Administrador de tareas
Global $bDisablePowerOff = False	; Deshabilitar el bóton de Apagar sistema
Global $bDisableReboot = False		; Deshabilitar el bóton de Reiniciar sistema

; ...línea de comandos
_ProcesarParametros()

Func _ProcesarParametros()
   For $i = 1 To $CmdLine[0]
	  Switch $CmdLine[$i]
		 Case "/GenerateHash", "/gh"
			_GenerarNuevoHash()
			Exit

		 Case "/PassHash", "/ph"
			If $i + 1 <= $CmdLine[0] Then
			   $sPasswordCorrecta = $CmdLine[$i + 1]
			   $i += 1 ; Saltamos al siguiente parámetro

			   ; Validación básica del hash
			   If StringLen($sPasswordCorrecta) <> 34 Or StringLeft($sPasswordCorrecta, 2) <> "0x" Then
				  MsgBox($MB_ICONERROR, "Error: Formato de hash inválido", "El hash debe comenzar con 0x seguido de 32 caracteres hex." & @CRLF & "ejemplo:" & @CRLF & @CRLF & @ScriptName & " /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD" & @CRLF & @CRLF & "Para generar uno, usa el parametro:" & @CRLF & @CRLF & @ScriptName & " /GenerateHash")
				  Exit
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
				  Case "1"	; dark
					 $iBkColorPanel = 0x050505
				  Case "2"	; aqua
					 $iBkColorPanel = 0x00696D
				EndSwitch
			EndIf

	  EndSwitch
   Next

   If $sPasswordCorrecta = "" Then
	  Local $iBoton = MsgBox($IDRETRY, "Error: Parametro faltante", "Debes generar/añadir un hash, ejemplo:" & @CRLF & @CRLF & @ScriptName & " /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD" & @CRLF & @CRLF & "Para generar uno, usa el parametro:" & @CRLF & @CRLF & @ScriptName & " /GenerateHash" & @CRLF & @CRLF & @CRLF & "¿Desea generarlo ya?")

	  If $iBoton = $IDYES Then
		 _GenerarNuevoHash()
	  EndIf

	  Exit
   EndIf

EndFunc

If $bDisableExplorer = True Then
   Run("taskkill /f /im explorer.exe", "", "", @SW_HIDE)
EndIf

If $bDisableTaskMgr = True Then
   RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "1")
EndIf

; Verificar instancia única
If _Singleton("VentanaBloqueoPantalla", 1) = 0 Then Exit

; Crear ventana principal (fullscreen)
Local $hGUI = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUISetBkColor($iBkColor, $hGUI)
WinSetTrans($hGUI, "", $iTransparencia)
GUISetState(@SW_SHOW, $hGUI)

; Crear ventana de contraseña (centrada)
Local $hPassGUI = GUICreate("", $iAnchoPass, $iAltoPass, -1, -1, $WS_POPUP, $WS_EX_TOPMOST, $hGUI)
GUISetBkColor($iBkColorPanel, $hPassGUI)
WinSetTrans($hPassGUI, "", $iTransparenciaPassGUI) ; Establecer transparencia para la ventana

; Posicionar controles
Local $idIcoPass = GUICtrlCreateIcon("shell32.dll", -245, ($iAnchoPass - 32) / 2, 10, 32, 32)
GUICtrlSetTip(-1, "¡Acceso Restringido!")

Local $idTxtPass = GUICtrlCreateLabel("Sistema bloqueado", 10, 45, $iAnchoPass - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 12, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idTxtMsg = GUICtrlCreateLabel("Escribe la palabra mágica:", 10, 65, $iAnchoPass - 10, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idInput = GUICtrlCreateInput("", 50, 90, $iAnchoPass - 100, 20, $ES_PASSWORD)
GUICtrlSetState(-1, $GUI_FOCUS)

Local $idErrorLabel = GUICtrlCreateLabel("", 10, 120, $iAnchoPass - 20, 20, $SS_CENTER)
GUICtrlSetColor(-1, $iStyle > 0 ? 0xFFEC00 : 0xFF0000) ; rojo/amarillo
GUICtrlSetFont(-1, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")

Local $topIcoBoton = 146, $topTxtBoton = 185

Local $idBotonUnlock = GUICtrlCreateButton(-1, 290, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -177)
;~ GUICtrlSetTip(-1, "Desbloquear")
GUICtrlCreateLabel("Desbloquear", 280, $topTxtBoton)
GUICtrlSetFont(-1, 8)
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idPowerOff = GUICtrlCreateButton(-1, 20, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetState(-1, $bDisablePowerOff ? $GUI_DISABLE : $GUI_ENABLE)
;~ GUICtrlSetTip(-1, "Apagar")
GUICtrlCreateLabel("Apagar", 22, $topTxtBoton)
GUICtrlSetFont(-1, 8)
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

Local $idReboot = GUICtrlCreateButton(-1, 65, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -239)
GUICtrlSetState(-1, $bDisableReboot ? $GUI_DISABLE : $GUI_ENABLE)
;~ GUICtrlSetTip(-1, "Reiniciar")
GUICtrlCreateLabel("Reiniciar", 65, $topTxtBoton)
GUICtrlSetFont(-1, 8)
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

GUICtrlCreateLabel("Inicio " & _Hora(), 140, 160)
GUICtrlSetFont(-1, 8, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

GUICtrlCreateLabel("MyLogin v" & $sVersion, 295, 5)
GUICtrlSetFont(-1, 6, $FW_NORMAL, $GUI_FONTNORMAL, "Consolas")
GUICtrlSetColor(-1, $iStyle > 0 ? $iColorTxt : 0x000000)

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Centrar y mostrar ventana
WinMove($hPassGUI, "", (@DesktopWidth - $iAnchoPass) / 2, (@DesktopHeight - $iAltoPass) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Bloquear teclas especiales
Local $aHotKeys = ["^", _ ; Ctrl
"!", _ ; Alt
"#", _ ; Win
"{F4}", "{DEL}", "{TAB}", "{HOME}", "{ESC}", "{UP}", "{DOWN}", "{LEFT}", "{RIGHT}", "{SPACE}"]

For $sKey In $aHotKeys
    HotKeySet($sKey, "_NoHacerNada")
Next

; Bucle principal
While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE, $idBotonUnlock
		 If _VerificarPassword() Then

			GUICtrlSetImage($idIcoPass, "imageres.dll", -102)
			GUISetBkColor(0x0FFF00, $hGUI)	; verde

			GUICtrlSetData($idTxtPass, "Desbloqueado")
			GUICtrlSetColor($idTxtPass, $iStyle > 0 ? 0x0FFF00 : 0x0F9800) ; verde claro/oscuro

			GUICtrlSetData($idTxtMsg, "")

			If $iFail > 0 Then

			   GUICtrlSetData($idErrorLabel, "")
			EndIf

			SoundPlay(@WindowsDir & "\media\ding.wav", $SOUND_NOWAIT)

			If $bDisableExplorer = True Then
			   Run(@WindowsDir & "\explorer.exe", "", @SW_HIDE)
			EndIf

			If $bDisableTaskMgr = True Then
			   RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableTaskMgr", "REG_DWORD", "0")
			EndIf

			Sleep(400)

			ExitLoop
		 EndIf

		 $iFail += 1

		 GUICtrlSetData($idErrorLabel, "(" & $iFail & ") Incorrecto, prueba otra vez...")
		 GUICtrlSetData($idInput, "")
		 GUICtrlSetState($idInput, $GUI_FOCUS)

		 SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

		 GUICtrlSetImage($idIcoPass, "imageres.dll", -101)
		 GUISetBkColor(0xFF0000, $hGUI)	; rojo

		 Sleep(300)

		 GUICtrlSetImage($idIcoPass, "shell32.dll", -245)
		 GUISetBkColor($iBkColor, $hGUI)

	  Case $idPowerOff
		 Run("shutdown -s -f -t 0", "", "", @SW_HIDE)

	  Case $idReboot
		 Run("shutdown -r -f -t 0", "", "", @SW_HIDE)

   EndSwitch

WEnd

; Limpieza y salida
GUIDelete($hPassGUI)
GUIDelete($hGUI)
Exit

Func _VerificarPassword()
   Return (_Hash_SHA1_SHA1_MD5(GUICtrlRead($idInput)) = $sPasswordCorrecta)
EndFunc

Func _NoHacerNada()
    ; No acción para teclas bloqueadas
	SoundPlay(@WindowsDir & "\media\Windows Hardware Fail.wav", $SOUND_NOWAIT)
 EndFunc

Func _Hash_SHA1_SHA1_MD5($sInput)
   Local $sHash = _Crypt_HashData($sInput, $CALG_SHA1)

   $sHash = _Crypt_HashData($sHash, $CALG_SHA1)

   $sHash = _Crypt_HashData($sHash, $CALG_MD5)

   Return $sHash
EndFunc

Func _Hora()
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

Func _GenerarNuevoHash()
   Local $bValida = False

   ; Bucle hasta que se ingrese una contraseña válida
   While Not $bValida
	  $sInput = InputBox("Generador de Hash", "Introduce la contraseña para generar el hash:" & @CRLF & @CRLF & "- Debe tener al menos 2 caracteres" & @CRLF & "- Sin espacios vacios", "", "*")

	  ; Si el usuario cancela
	  If @error Then
		 MsgBox($MB_ICONINFORMATION, "Información", "Generación de hash cancelada")
		 Exit
	  EndIf

	  ; Validaciones
	  If StringLen($sInput) < 2 Then
		 MsgBox($MB_ICONWARNING, "Error", "La contraseña debe tener al menos 2 caracteres")
	  ElseIf StringIsSpace($sInput) Then
		 MsgBox($MB_ICONWARNING, "Error", "La contraseña no puede contener solo espacios")
	  ElseIf StringInStr($sInput, " ") Then
		 MsgBox($MB_ICONWARNING, "Error", "La contraseña no puede contener espacios")
	  Else
		 $bValida = True
	  EndIf
   WEnd

   ; Generar y mostrar el hash
   InputBox("Hash generado", "Has introducido la siguiente contraseña:" & @CRLF & @CRLF & $sInput & @CRLF & @CRLF & "Su nuevo hash es:", _Hash_SHA1_SHA1_MD5($sInput))
EndFunc
