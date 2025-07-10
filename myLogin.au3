#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <AutoItConstants.au3>
#include <Crypt.au3>

; Configuración global
Global $sPasswordCorrecta = "0xBB7B85A436B38DFAE3756DDF54AF46CD"
Global $iTransparencia = 150       ; 0-255 (transparente-opaco)
Global $iTransparenciaPassGUI = 225 ; 0-255 (transparente-opaco) para ventana de contraseña
Global $iColorFondo = 0x000000     ; Color de fondo negro
Global $iAnchoPass = 350           ; Ancho ventana contraseña
Global $iAltoPass = 200            ; Alto ventana contraseña
Global $iFail = 0

; Verificar instancia única
If _Singleton("VentanaBloqueoPantalla", 1) = 0 Then Exit

; Crear ventana principal (fullscreen)
Local $hGUI = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUISetBkColor($iColorFondo, $hGUI)
WinSetTrans($hGUI, "", $iTransparencia)
GUISetState(@SW_SHOW, $hGUI)

; Crear ventana de contraseña (centrada)
Local $hPassGUI = GUICreate("Acceso Restringido", $iAnchoPass, $iAltoPass, -1, -1, $WS_POPUP, $WS_EX_TOPMOST, $hGUI)
GUISetBkColor(0xFFFFFF, $hPassGUI)
WinSetTrans($hPassGUI, "", $iTransparenciaPassGUI) ; Establecer transparencia para la ventana blanca

; Posicionar controles
GUICtrlCreateIcon("shell32.dll", -245, ($iAnchoPass - 32) / 2, 10, 32, 32)
GUICtrlSetTip(-1, "¡Virus detectado!")

Local $idLabel = GUICtrlCreateLabel("Sistema bloqueado" & @CRLF & "Escribe la palabra mágica:", _
                     10, 50, $iAnchoPass - 20, 40, $SS_CENTER)
GUICtrlSetFont($idLabel, 10, $FW_SEMIBOLD, $GUI_FONTNORMAL, "Consolas")

Local $idInput = GUICtrlCreateInput("", 50, 90, $iAnchoPass - 100, 20, $ES_PASSWORD)
GUICtrlSetState($idInput, $GUI_FOCUS)  ; Establece el foco en el input

Local $idErrorLabel = GUICtrlCreateLabel("", 10, 120, $iAnchoPass - 20, 20, $SS_CENTER)
GUICtrlSetColor($idErrorLabel, 0xFF0000)

Local $topIcoBoton = 146, $topTxtBoton = 185

Local $idBoton = GUICtrlCreateButton(-1, 290, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage($idBoton, "shell32.dll", -300)
;~ GUICtrlSetTip($idBoton, "Desbloquear")
GUICtrlCreateLabel("Desbloquear", 280, $topTxtBoton)
GUICtrlSetFont(-1, 8)

;~ GUICtrlCreateButton("Desbloquear", ($iAnchoPass - 100) / 2, 150, 100, 30)

Local $idOff = GUICtrlCreateButton(-1, 20, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage($idOff, "shell32.dll", -28)
;~ GUICtrlSetTip($idOff, "Apagar")
GUICtrlCreateLabel("Apagar", 22, $topTxtBoton)
GUICtrlSetFont(-1, 8)

Local $idRst = GUICtrlCreateButton(-1, 65, $topIcoBoton, 40, 40, $BS_ICON)
GUICtrlSetImage($idRst, "shell32.dll", -239)
;~ GUICtrlSetTip($idRst, "Reiniciar")
GUICtrlCreateLabel("Reiniciar", 65, $topTxtBoton)
GUICtrlSetFont(-1, 8)

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Centrar y mostrar ventana
WinMove($hPassGUI, "", (@DesktopWidth - $iAnchoPass) / 2, (@DesktopHeight - $iAltoPass) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Bloquear teclas especiales
Local $aHotKeys = ["{ESC}", "^{ESC}", "!{F4}", "^{ALT}{DEL}", "#{TAB}", "#{r}", "{HOME}", "{TAB}", "#", "^{TAB}"]
For $sKey In $aHotKeys
    HotKeySet($sKey, "_NoHacerNada")
Next

; Bucle principal
While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE, $idBoton
            If _VerificarPassword() Then

			   SoundPlay(@WindowsDir & "\media\ding.wav", $SOUND_NOWAIT)

			   GUISetBkColor(0x00FF00, $hGUI)

			   Sleep(300)

			   ExitLoop
			EndIf

			$iFail += 1

            GUICtrlSetData($idErrorLabel, "(" & $iFail & ") Incorrecto, Intente nuevamente.")
            GUICtrlSetData($idInput, "")
			GUICtrlSetState($idInput, $GUI_FOCUS)

			SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

			GUISetBkColor(0xFF0000, $hGUI)

			Sleep(300)

			GUISetBkColor($iColorFondo, $hGUI)

			If $iFail = 3 Then
			   GUIDelete($hPassGUI)
			   GUIDelete($hGUI)
			   Exit
			EndIf

		 Case $idOff
			Shutdown($SD_FORCE + $SD_POWERDOWN)

		 Case $idRst
			Shutdown($SD_FORCE + SD_REBOOT)

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
	SoundPlay(@WindowsDir & "\media\Windows Error de hardware.wav", $SOUND_NOWAIT)
 EndFunc

Func _Hash_SHA1_SHA1_MD5($sInput)
   Local $sHash = _Crypt_HashData($sInput, $CALG_SHA1)

   $sHash = _Crypt_HashData($sHash, $CALG_SHA1)

   $sHash = _Crypt_HashData($sHash, $CALG_MD5)

   Return $sHash
EndFunc
