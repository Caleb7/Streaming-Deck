#cs ----------------------------------------------------------------------------
 AutoIt Version:
	3.3.14.5
 Author:
	Caleb Tyler Alexander
 Script Function:
	Custom sound board for streaming, with hotkeys
	Written for pikeg2 on Fiverr
#ce ----------------------------------------------------------------------------
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <SendMessage.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <Sound.au3>
#include <File.au3>
#include <WinAPISys.au3>
#include <Misc.au3>

; <Settings> - Global settings used inside the app
Global $VERSION = "1.0"
Global $APP_TITLE = "Pike Streaming Deck"
Global $GUI_Style = BitOR($WS_SYSMENU,$WS_POPUP) ; adding $WS_POPUPWINDOW in BitOR gives a thin border
Global $GUI_Color_Background = 0x323232
Global $Button_Color_Background = 0x222222
Global $Button_Color_Font = 0xFFFFFF
Global $Button_Color_Selected = 0x050505
Global $Button_Font = "Sans"
Global $Button_Font_Size = 11
Global $Button_Font_Weight = 800
Global $SleepAfterPlay = 250 			; minimum time between sound plays
Global $About_Dialog = FileRead( @ScriptDir & "\data\about.txt" )
; </Settings>

; Other global variables that are used, shouldn't be edited
Global $hUser32DLL
Global $EditMode = 0
Global $Config_File = @ScriptDir & "\data\config.ini"
Global $MainGUI
Global $EditGUI
Global $AboutGUI
Global $ButtonSoundFile[36]
Global $ButtonName[36]
Global $Hotkey1[36]
Global $Hotkey2[36]
Global $Hotkey3[36]
Global $LocalFile[36]
Global $IsFolder[36]
Global $PossibleKeys = StringSplit( "01|MOUSE1|02|MOUSE2|03|Controlbreak|04|MOUSE3|05|X1MOUSE|06|X2MOUSE|08|BACKSPACE|09|TAB|0C|CLEAR|0D|ENTER|10|SHIFT|11|CTRL|12|ALT|13|PAUSE|14|CAPSLOCK|1B|ESC|20|SPACEBAR|21|PAGEUP|22|PAGEDOWN|23|END|24|HOME|25|LEFT|26|UP|27|RIGHT|28|DOWN|29|SELECT|2A|PRINT|2B|EXECUTE|2C|PRINTSCREEN|2D|INS|2E|DEL|30|0|31|1|32|2|33|3|34|4|35|5|36|6|37|7|38|8|39|9|41|A|42|B|43|C|44|D|45|E|46|F|47|G|48|H|49|I|4A|J|4B|K|4C|L|4D|M|4E|N|4F|O|50|P|51|Q|52|R|53|S|54|T|55|U|56|V|57|W|58|X|59|Y|5A|Z|5B|LWIN|5C|RWIN|5D|PopUp|60|numpad0|61|numpad1|62|numpad2|63|numpad3|64|numpad4|65|numpad5|66|numpad6|67|numpad7|68|numpad8|69|numpad9|6A|Multiply|6B|Add|6C|Separator|6D|Subtract|6E|Decimal|6F|Divide|70|F1|71|F2|72|F3|73|F4|74|F5|75|F6|76|F7|77|F8|78|F9|79|F10|7A|F11|7B|F12|90|NUM|LOCK|91|SCROLL|LOCK|A0|LSHIFT|A1|RSHIFT|A2|LCONTROL|A3|RCONTROL|A4|LMENU|A5|RMENU|BA|;|BB|=|BC|,|BD|-|BE|.|BF|/|C0|`|DB|[|DC|\|DD|]", "|", 3 )
Global $__Restart = False
Global $WavVolume = IniRead( $Config_File, "Volume", "Value", 50 )
_Main()

; The main GUI with buttons to play sounds, with settings, edit, stop, minimize and exit controls
Func _Main_GUI()
	$Button_Color_Background = IniRead( $Config_File, "Theme", "Button_Color", $Button_Color_Background )
	$Button_Color_Font = IniRead( $Config_File, "Theme", "Font_Color", $Button_Color_Font )
	$GUI_Color_Background = IniRead( $Config_File, "Theme", "GUI_Color", $GUI_Color_Background )
	Global $Button[36]
	Global $ButtonX[36] = [ 8, 104, 200, 296, 392, 8,  104, 200, 296, 392, 8,  104, 200, 296, 392, 8,   104, 200, 296, 392, 8,   104, 200, 296, 392, 8,   104, 200, 296, 392, 8,   104, 200, 296, 392 ]
	Global $ButtonY[36] = [ 8, 8,   8,   8,   8,   40, 40,  40,  40,  40,  72, 72,  72,  72,  72,  104, 104, 104, 104, 104, 136, 136, 136, 136, 136, 168, 168, 168, 168, 168, 200, 200, 200, 200, 200 ]
	Global $ButtonWidth = 91
	Global $ButtonHeight = 25
	Global $ButtonText[36] = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "Settings", "Edit", "Stop", "Minimize", "Exit" ]
	$MainGUI = GUICreate($APP_TITLE, 491, 234, 219, 144, $GUI_Style)
	GUISetBkColor($GUI_Color_Background)
	For $i = 0 To 34
		$Button[$i] = GUICtrlCreateLabel( $ButtonText[$i], $ButtonX[$i], $ButtonY[$i], $ButtonWidth, $ButtonHeight, BitOR($SS_CENTER, $SS_CENTERIMAGE) )
		GUICtrlSetColor(-1, $Button_Color_Font)
		GUICtrlSetBkColor(-1, $Button_Color_Background)
		GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	Next
	_Config_Load()
	GUISetState(@SW_SHOW)
EndFunc

; The edit gui, for putting in file, setting hotkeys and naming buttons
Func _Edit_GUI( $index )
	GUICtrlSetBkColor( $Button[$index], $Button_Color_Selected )
	$EditGUI = GUICreate("EditGUI", 491, 153, 206, 149, $GUI_Style)
	GUISetBkColor($GUI_Color_Background)
	$Save = GUICtrlCreateLabel("Save", 392, 56, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Delete = GUICtrlCreateLabel("Delete", 392, 88, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Path = GUICtrlCreateInput("", 8, 120, 379, 24)
	GUICtrlSetColor(-1, 0x000000)
	$Browse = GUICtrlCreateLabel("File", 392, 120, 43, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Folder = GUICtrlCreateLabel("Folder", 440, 120, 43, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 3, $Button_Font_Weight, 0, $Button_Font )
	$Name = GUICtrlCreateInput("", 184, 24, 91, 20)
	GUICtrlSetColor(-1, 0x000000)
	$Key1 = GUICtrlCreateInput("", 8, 24, 73, 23)
	GUICtrlSetColor(-1, 0x000000)
	$Key2 = GUICtrlCreateInput("", 8, 48, 73, 23)
	GUICtrlSetColor(-1, 0x000000)
	$Key3 = GUICtrlCreateInput("", 8, 72, 73, 23)
	GUICtrlSetColor(-1, 0x000000)
	$Label3 = GUICtrlCreateLabel("File", 8, 102, 55, 17)
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetFont(-1, $Button_Font_Size, $Button_Font_Weight, 0, $Button_Font )
	$Label4 = GUICtrlCreateLabel("Name", 184, 6, 55, 17)
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetFont(-1, $Button_Font_Size, $Button_Font_Weight, 0, $Button_Font )
	$Label5 = GUICtrlCreateLabel("Hotkey", 8, 6, 75, 17)
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetFont(-1, $Button_Font_Size, $Button_Font_Weight, 0, $Button_Font )
	$Exit = GUICtrlCreateLabel("Go Back", 392, 24, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Set1 = GUICtrlCreateLabel("Set", 88, 24, 35, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Set2 = GUICtrlCreateLabel("Set", 88, 48, 35, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Set3 = GUICtrlCreateLabel("Set", 88, 72, 35, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Clear1 = GUICtrlCreateLabel("Clear", 128, 24, 45, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Clear2 = GUICtrlCreateLabel("Clear", 128, 48, 45, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Clear3 = GUICtrlCreateLabel("Clear", 128, 72, 45, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	If $ButtonName[$index] <> "" Then
		GUICtrlSetData( $Name, $ButtonName[$index] )
	EndIf
	If $ButtonSoundFile[$index] Then
		GUICtrlSetData( $Path, $ButtonSoundFile[$index] )
	EndIf
	If $Hotkey1[$index] Then
		GUICtrlSetData( $Key1, _HexTokey( $Hotkey1[$index] ) )
	EndIf
	If $Hotkey2[$index] Then
		GUICtrlSetData( $Key2, _HexTokey( $Hotkey2[$index] ) )
	EndIf
	If $Hotkey3[$index] Then
		GUICtrlSetData( $Key3, _HexTokey( $Hotkey3[$index] ) )
	EndIf
	GUISetState(@SW_SHOW)

	While 1
		; keeps child GUI under parent
		$xy = WinGetPos( $APP_TITLE, "" )
		WinMove( "EditGUI", "", $xy[0], $xy[1] + 200 )
		If WinActive( $APP_TITLE ) Then
			WinActivate( "EditGUI" )
		EndIf

		$nMsg = GUIGetMsg()
		Switch $nMsg
			; clear buttons
			Case $Clear1
				GUICtrlSetData( $Key1, "" )
			Case $Clear2
				GUICtrlSetData( $Key2, "" )
			Case $Clear3
				GUICtrlSetData( $Key3, "" )
			Case $Delete
				; will delete all settings inside the edit gui
				GUICtrlSetData( $Button[$index], "" )
				IniWrite( $Config_File, "Button" & $index, "Name", "" )
				$ButtonName[$index] = ""
				GUICtrlSetTip( $Button[$index], "" )
				IniWrite( $Config_File, "Button" & $index, "Sound", "" )
				$ButtonSoundFile[$index] = ""
				$Hotkey1[$index] = ""
				IniWrite( $Config_File, "Button" & $index, "Key1", "" )
				$Hotkey2[$index] = ""
				IniWrite( $Config_File, "Button" & $index, "Key2", "" )
				$Hotkey3[$index] = ""
				IniWrite( $Config_File, "Button" & $index, "Key3", "" )
				$LocalFile[$index] = ""
				GUICtrlSetBkColor( $Button[$index], $Button_Color_Background )
				GUIDelete( $EditGUI )
				ExitLoop
			Case $Save
				; save all settings in the edit gui to ini file
				Local $sName = GUICtrlRead( $Name )
				GUICtrlSetData( $Button[$index], $sName )
				IniWrite( $Config_File, "Button" & $index, "Name", $sName )
				$ButtonName[$index] = $sName

				Local $sSound = GUICtrlRead( $Path )
				IniWrite( $Config_File, "Button" & $index, "Sound", $sSound )
				$ButtonSoundFile[$index] = $sSound
				$sExt = StringRight( $ButtonSoundFile[ $index ], 4 )

				If StringRight( $sExt, 1 ) == "\" Then
					$IsFolder[$index] = True
				Else
					$IsFolder[$index] = False
					Switch $sExt
						Case ".mp3"
							$LocalFile[$index] = True
						Case ".wav"
							$LocalFile[$index] = True
						Case Else
							$LocalFile[$index] = False
					EndSwitch
				EndIf
				IniWrite( $Config_File, "Button" & $index, "Local", $LocalFile[$index] )
				IniWrite( $Config_File, "Button" & $index, "Folder", $IsFolder[$index] )
				$sHK = ""

				$K1 = GUICtrlRead( $Key1 )
				If $K1 <> "" Then
					$Hotkey1[$index] = _KeyToHex( $K1 )
					$sHK &= $K1
				EndIf
				IniWrite( $Config_File, "Button" & $index, "Key1", $K1 )

				$K2 = GUICtrlRead( $Key2 )
				If $K2 <> "" Then
					$Hotkey2[$index] = _KeyToHex( $K2 )
					$sHK &= " + " & $K2
				EndIf
				IniWrite( $Config_File, "Button" & $index, "Key2", $K2 )

				$K3 = GUICtrlRead( $Key3 )
				If $K3 <> "" Then
					$Hotkey3[$index] = _KeyToHex( $K3 )
					$sHK &= " + " & $K3
				EndIf
				IniWrite( $Config_File, "Button" & $index, "Key3", $K3 )

				GUICtrlSetBkColor( $Button[$index], $Button_Color_Background )
				$rsplit = StringSplit( $sSound, "\", 3 )
				$sound = $rsplit[ UBound($rsplit) - 1 ]
				GUICtrlSetTip( $Button[$index], "File: " & $sound & @CRLF & "Hotkey: " & $sHK )
				GUIDelete( $EditGUI )
				ExitLoop
			Case $Browse
				; browse for files to play/run in the edit gui
				$SoundPath = FileOpenDialog( "Sound browser", @ScriptDir & "\data\", "All Files(*.*)|mp3 (*.mp3)|mp4 (*.mp4)|wav (*.wav)|executable (*.exe)", 1 )
				$sExt = StringRight( $SoundPath, 4 )
				Switch $sExt
					Case ".mp3"
						$LocalFile[$index] = True
					Case ".wav"
						$LocalFile[$index] = True
					Case Else
						$LocalFile[$index] = False
				EndSwitch
				If $LocalFile[$index] Then
					$RSound = StringSplit( $SoundPath, "\", 3 )
					$SoundFile = $RSound[ UBound( $RSound ) - 1 ]
					If NOT FileExists( @ScriptDir & "\data\" & $SoundFile ) Then
						;MsgBox( 0, "", $SoundPath & @CRLF & $SoundFile & @CRLF & @ScriptDir & "\data\" )
						FileCopy( $SoundPath, @ScriptDir & "\data\" )
					EndIf
					GUICtrlSetData( $Path, $SoundFile, "" )
					FileChangeDir(@ScriptDir)
				Else
					GUICtrlSetData( $Path, $SoundPath, "" )
				EndIf
			Case $Folder
				Local $folderpath = FileSelectFolder( "Folder browser", "" )
				GUICtrlSetData( $Path, $folderpath & "\" )
				FileChangeDir(@ScriptDir)
			Case $Exit
				GUICtrlSetBkColor( $Button[$index], $Button_Color_Background )
				GUIDelete( $EditGUI )
				ExitLoop
			Case $Set1
				; set hotkeys
				$Setkey = _SetKeyGUI()
				If $Setkey <> "" Then
					GUICtrlSetData( $Key1, _HexToKey( $Setkey ) )
				EndIf
			Case $Set2
				$Setkey = _SetKeyGUI()
				If $Setkey <> "" Then
					GUICtrlSetData( $Key2, _HexToKey( $Setkey ) )
				EndIf
			Case $Set3
				$Setkey = _SetKeyGUI()
				If $Setkey <> "" Then
					GUICtrlSetData( $Key3, _HexToKey( $Setkey ) )
				EndIf
		EndSwitch
		For $i = 30 To 34
			Switch $nMsg
				Case $Button[$i]
					_Button_Call( $i )
			EndSwitch
		Next
		If $EditMode == 0 Then
			GUICtrlSetBkColor( $Button[$index], $Button_Color_Background )
			GUIDelete( $EditGUI )
			ExitLoop
		EndIf
	WEnd
EndFunc

; the settings/about gui
Func _About_GUI()
	$AboutGUI = GUICreate("SettingsGUI", 491, 148, 380, 268, $GUI_Style)
	GUISetBkColor($GUI_Color_Background)
	$AboutExit = GUICtrlCreateLabel("Go Back", 392, 104, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Icon1 = GUICtrlCreateIcon(@ScriptDir & "\data\icon.ico", -1, 8, 8, 88, 120)
	$Label3 = GUICtrlCreateLabel($About_Dialog, 104, 8, 283, 122)
	GUICtrlSetColor(-1, $Button_Color_Font)
	;GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Button1 = GUICtrlCreateLabel("Button", 392, 40, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Button2 = GUICtrlCreateLabel("Font", 392, 72, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Button3 = GUICtrlCreateLabel("Background", 392, 8, 91, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	$Slider = GUICtrlCreateSlider( 8, 135, 475, 8 )
	GUICtrlSetLimit(-1, 100, 0 )
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetBkColor(-1, $Button_Color_Background)
	GUICtrlSetFont(-1, $Button_Font_Size - 2, $Button_Font_Weight, 0, $Button_Font )
	GUICtrlSetData(-1, $WavVolume )
	GUISetState(@SW_SHOW)

	While 1
		$xy = WinGetPos( $APP_TITLE, "" )
		WinMove( "SettingsGUI", "", $xy[0], $xy[1] + 200 )
		If WinActive( $APP_TITLE ) Then
			WinActivate( "SettingsGUI" )
		EndIf
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				_Exit()
			Case $AboutExit
				GUIDelete( $AboutGUI )
				ExitLoop
			Case $Button[30]
				GUIDelete( $AboutGUI )
				ExitLoop
			Case $Button1 ; button bg
				$Color = _ChooseColor(2)
				If $Color <> -1 Then
					$Button_Color_Background = $Color
					IniWrite( $Config_File, "Theme", "Button_Color", $Color )
					_ScriptRestart()
				EndIf
			Case $Button2
				$Color = _ChooseColor(2)
				If $Color <> -1 Then
					$Button_Color_Font = $Color
					IniWrite( $Config_File, "Theme", "Font_Color", $Color )
					_ScriptRestart()
				EndIf
			Case $Button3
				$Color = _ChooseColor(2)
				If $Color <> -1 Then
					$GUI_Color_Background = $Color
					IniWrite( $Config_File, "Theme", "GUI_Color", $Color )
					_ScriptRestart()
				EndIf
			Case $Slider
				$WavVolume = GUICtrlRead( $Slider )
				SoundSetWaveVolume( $WavVolume )
				IniWrite( $Config_File, "Volume", "Value", $WavVolume )
		EndSwitch

		For $i = 0 To 29
			Switch $nMsg
				Case $Button[$i]
					_Button_Call( $i )
			EndSwitch
		Next

		Local $index = _Hotkey_Check()
		If $index >= 0 Then
			If $ButtonSoundFile[ $index ] == "" Then
				SoundPlay( "" )
			Else
				If $IsFolder[$index] Then
					_OpenFolder( $ButtonSoundFile[ $index ] )
				Else
					$sExt = StringRight( $ButtonSoundFile[ $index ], 4 )
					Switch $sExt
						Case ".mp3"
							SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
						Case ".wav"
							SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
						Case ".exe"
							Run( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
						Case Else
							Run( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
					EndSwitch
				EndIf
				Sleep( $SleepAfterPlay )
			EndIf
		EndIf
	WEnd
EndFunc

; the gui that pops up while waiting for keys to be pressed for hotkeys
Func _SetKeyGUI()
	Global $SetKeyGUI = GUICreate("SetKeyGUI", 491, 153, 206, 149, $GUI_Style)
	GUISetBkColor($GUI_Color_Background)
	$xy = WinGetPos( "EditGUI" )
	WinMove( "SetKeyGUI", "", $xy[0], $xy[1] )
	GUISetState( @SW_SHOW )
	$KeyControl = GUICtrlCreateLabel( "Press any key or {ESC} to exit", 0, 0, 491, 153, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $Button_Color_Font)
	GUICtrlSetFont(-1, $Button_Font_Size, $Button_Font_Weight, 0, $Button_Font )

	Local $Key = ""

	While $Key == ""

		$xy = WinGetPos( $APP_TITLE, "" )
		WinMove( "SetKeyGUI", "", $xy[0], $xy[1] + 200 )
		If WinActive( $APP_TITLE ) Then
			WinActivate( "SetKeyGUI" )
		EndIf

		If _IsPressed( "1B", $hUser32DLL ) Then
			GUIDelete( $SetKeyGUI )
			Return ""
		EndIf

		For $i = 3 To 256
			Local $hex = String( Hex( $i, 2 ) )
			If _IsPressed( $hex ) Then
				$Key = $hex
			EndIf
		Next
	WEnd

	GUICtrlSetData( $KeyControl, "Key set to: " & $Key )
	Sleep( 200 )
	GUIDelete( $SetKeyGUI )
	Return $Key

EndFunc

; close dll used by _IsPressed
Func _Exit()
	DllClose($hUser32DLL)
	Exit
EndFunc

; allows window movement without title bar
Func WM_NCHITTEST($hWnd, $iMsg, $iwParam, $ilParam)
	If ( $hWnd == $MainGUI OR $hWnd == $EditGUI OR $hWnd == $AboutGUI ) And $iMsg = $WM_NCHITTEST Then Return $HTCAPTION
EndFunc

; checks for hotkeys and returns hotkey id
Func _Hotkey_Check()
	For $i = 0 To 29
		If $Hotkey1[$i] <> "" Then
			If _IsPressed( $Hotkey1[$i], $hUser32DLL ) Then
				If $Hotkey2[$i] <> "" Then
					If _IsPressed( $Hotkey2[$i], $hUser32DLL ) Then
						If $Hotkey3[$i] <> "" Then
							If _IsPressed( $Hotkey3[$i], $hUser32DLL ) Then
								Return $i
							EndIf
						Else
							Return $i
						EndIf
					EndIf
				Else
					Return $i
				EndIf
			EndIf
		EndIf
	Next
	Return -1
EndFunc

; calls buttons that are pressed with mouse
Func _Button_Call( $index )
	If $index >= 30 Then
		Switch $index
			Case 30
				_About_GUI()
			Case 31
				If $EditMode == 1 Then
					$EditMode = 0
					GUICtrlSetBkColor( $Button[31], $Button_Color_Background )
					GUICtrlSetColor( $Button[31], $Button_Color_Font )
				Else
					$EditMode = 1
					GUICtrlSetColor( $Button[31], 0xFF0000 )
					GUICtrlSetBkColor( $Button[31], 0x00FF00 )
				EndIf
			Case 32
				SoundPlay( "" )
			Case 33
				WinSetState( $MainGUI, "", @SW_MINIMIZE )
			Case 34
				_Exit()
		EndSwitch
	Else
		Switch $EditMode
			Case 1
				_Edit_GUI( $index )
			Case 0
				If $ButtonSoundFile[ $index ] == "" Then
					SoundPlay( "" )
				Else
					If $IsFolder[$index] Then
						_OpenFolder( $ButtonSoundFile[ $index ] )
					Else
						$sExt = StringRight( $ButtonSoundFile[ $index ], 4 )
						Switch $sExt
							Case ".mp3"
								SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
							Case ".wav"
								SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
							Case ".exe"
								Run( $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
							Case Else
								Run( $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
						EndSwitch
					EndIf
					Sleep( $SleepAfterPlay )
				EndIf
		EndSwitch
	EndIf
EndFunc

; loads settings from config
Func _Config_Load()
	For $i = 0 To 29
		$ButtonName[$i] = IniRead( $Config_File, "Button" & $i, "Name", "" )
		If $ButtonName[$i] <> "" Then
			GUICtrlSetData( $Button[$i], $ButtonName[$i] )
		EndIf
		$ButtonSoundFile[$i] = IniRead( $Config_File, "Button" & $i, "Sound", "" )
		If $ButtonSoundFile[$i] <> "" Then
			GUICtrlSetTip( $Button[$i], $ButtonSoundFile[$i] )
		EndIf
		$Hotkey1[$i] = _KeyToHex( IniRead( $Config_File, "Button" & $i, "Key1", "" ) )
		$Hotkey2[$i] = _KeyToHex( IniRead( $Config_File, "Button" & $i, "Key2", "" ) )
		$Hotkey3[$i] = _KeyToHex( IniRead( $Config_File, "Button" & $i, "Key3", "" ) )
		$LocalFile[$i] = IniRead( $Config_File, "Button" & $i, "Local", True )
		;If $LocalFile[$i] == "True" Then $LocalFile[$i] = True
		;If $LocalFile[$i] == "False" Then $LocalFile[$i] = False
		$IsFolder[$i] = IniRead( $Config_File, "Button" & $i, "Folder", False )
		If $IsFolder[$i] == "True" Then $IsFolder[$i] = True
		If $IsFolder[$i] == "False" Then $IsFolder[$i] = False
	Next
EndFunc

; main while loop + loads main gui on start
Func _Main()
	_Main_GUI()
	GUIRegisterMsg( $WM_NCHITTEST, "WM_NCHITTEST" )
	$hUser32DLL = DllOpen("user32.dll")
	While 1
		If $EditMode == 0 Then
			Local $index = _Hotkey_Check()
			If $index >= 0 Then
				If $ButtonSoundFile[ $index ] == "" Then
					SoundPlay( "" )
				Else
					If $IsFolder[$index] Then
						_OpenFolder( $ButtonSoundFile[ $index ] )
					Else
						$sExt = StringRight( $ButtonSoundFile[ $index ], 4 )
						Switch $sExt
							Case ".mp3"
								SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
							Case ".wav"
								SoundPlay( @ScriptDir & "\data\" & $ButtonSoundFile[ $index ], 0 )
							Case ".exe"
								Run( $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
							Case Else
								Run( $ButtonSoundFile[ $index ], @ScriptDir & "\data\" )
						EndSwitch
					EndIf
					Sleep( $SleepAfterPlay )
				EndIf
			EndIf
		EndIf
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				;_Exit()
		EndSwitch
		For $i = 0 To 34
			Switch $nMsg
				Case $Button[$i]
					_Button_Call( $i )
			EndSwitch
		Next
	WEnd
EndFunc

; convers hex to key name, and key name to hex
Func _HexToKey( $key )
	For $j = 0 To UBound( $PossibleKeys ) - 1 Step 2
		If $PossibleKeys[$j] == $key Then
			Return $PossibleKeys[$j+1]
		EndIf
	Next
EndFunc

Func _KeyToHex( $hex )
	For $j = 1 To UBound( $PossibleKeys ) - 1 Step 2
		If $PossibleKeys[$j] == $hex Then
			Return $PossibleKeys[$j-1]
		EndIf
	Next
EndFunc

; restarts the script to refresh gui colors
Func _ScriptRestart()
	Local $Pid
	Local $fExit = 1
	If Not $__Restart Then
		If @compiled Then
			$Pid = Run(@ScriptFullPath & ' ' & $CmdLineRaw, @ScriptDir, Default, 1)
		Else
			$Pid = Run(@AutoItExe & ' "' & @ScriptFullPath & '" ' & $CmdLineRaw, @ScriptDir, Default, 1)
		EndIf
		If @error Then
			Return SetError(@error, 0, 0)
		EndIf
		StdinWrite($Pid, @AutoItPID)
	EndIf
	$__Restart = 1
	If $fExit Then
		Sleep(50)
		Exit
	EndIf
	Return 1
EndFunc   ;==>_ScriptRestart

Func _OpenFolder( $path )
	Run( "explorer.exe " & $path )
EndFunc