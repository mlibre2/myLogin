#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <AutoItConstants.au3>

; Configuración global
Global $sPasswordCorrecta = "0."    ; Contraseña correcta
Global $iTransparencia = 128       ; 0-255 (transparente-opaco)
Global $iTransparenciaPassGUI = 225 ; 0-255 (transparente-opaco) para ventana de contraseña
Global $iColorFondo = 0x000000     ; Color de fondo negro
Global $iAnchoPass = 350           ; Ancho ventana contraseña
Global $iAltoPass = 200            ; Alto ventana contraseña

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
Local $iPosX = ($iAnchoPass - 32) / 2
GUICtrlCreateIcon("shell32.dll", -245, $iPosX, 10, 32, 32)

Local $idLabel = GUICtrlCreateLabel("Sistema bloqueado" & @CRLF & "Ingrese la contraseña:", _
                     10, 45, $iAnchoPass - 20, 40, $SS_CENTER)
GUICtrlSetFont($idLabel, 10, 600)

Local $idInput = GUICtrlCreateInput("", 50, 90, $iAnchoPass - 100, 20, $ES_PASSWORD)
GUICtrlSetState($idInput, $GUI_FOCUS)  ; Establece el foco en el input
Local $idErrorLabel = GUICtrlCreateLabel("", 10, 120, $iAnchoPass - 20, 20, $SS_CENTER)
GUICtrlSetColor($idErrorLabel, 0xFF0000)
Local $idBoton = GUICtrlCreateButton("Desbloquear", ($iAnchoPass - 100) / 2, 150, 100, 30)

SoundPlay(@WindowsDir & "\media\tada.wav", $SOUND_NOWAIT)

; Centrar y mostrar ventana
WinMove($hPassGUI, "", (@DesktopWidth - $iAnchoPass) / 2, (@DesktopHeight - $iAltoPass) / 2)
GUISetState(@SW_SHOW, $hPassGUI)

; Bloquear teclas especiales
Local $aHotKeys = ["{ESC}", "^{ESC}", "!{F4}", "^{ALT}{DEL}", "#{TAB}", "#{r}"]
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

            GUICtrlSetData($idErrorLabel, "Incorrecto. Intente nuevamente.")
            GUICtrlSetData($idInput, "")
			GUICtrlSetState($idInput, $GUI_FOCUS)

			SoundPlay(@WindowsDir & "\media\chord.wav", $SOUND_NOWAIT)

			GUISetBkColor(0xFF0000, $hGUI)

			Sleep(300)

			GUISetBkColor($iColorFondo, $hGUI)
    EndSwitch
WEnd

; Limpieza y salida
GUIDelete($hPassGUI)
GUIDelete($hGUI)
Exit

Func _VerificarPassword()
    Return (GUICtrlRead($idInput) = $sPasswordCorrecta)
EndFunc

Func _NoHacerNada()
    ; No acción para teclas bloqueadas
	SoundPlay(@WindowsDir & "\media\Windows Error de hardware.wav", $SOUND_NOWAIT)
EndFunc