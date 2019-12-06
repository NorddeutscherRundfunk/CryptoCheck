#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\Icons\key.ico
#AutoIt3Wrapper_Res_Comment=Checkt Prüfsumme nach CR32, MD4, MD5 und SHA1.
#AutoIt3Wrapper_Res_Description=Checkt Prüfsumme nach CR32, MD4, MD5 und SHA1.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.5
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_Field=Copyright|Conrad Zelck
#AutoIt3Wrapper_Res_Field=Compile Date|%date% %time%
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ExtMsgBox.au3>
#include <String.au3>
#include <File.au3>
#include <TrayCox.au3> ; source: https://github.com/SimpelMe/TrayCox

Opt("MustDeclareVars", 1)

Local $sFile = $CmdLineRaw
$sFile = StringReplace($sFile,'"',""); Wenn Leerzeichen o.ä. im Namen dann tauchen vorne und hinten " auf
Local $sTempFile

Global $sDrive = "", $sDir = "", $sFileName = "", $sExtension = "" ; für folgenden _PathSplit
Global $aFile = _PathSplit($sFile, $sDrive, $sDir, $sFileName, $sExtension) ; wird für Anzeige Dateiname im GUI-Titel benötigt

Global $hTimer, $iTimer, $sDataCR32, $sDataMD4, $sDataMD5, $sDataSHA1, $sPaste, $sHex
Global $sBackColor = Default

$sPaste = _StringIsHex(StringUpper(ClipGet()))

If $sFile > "" Then
	_Encrypt($sFile)
EndIf

Global $iReturn

Do

	$sBackColor = _BackColor()
	_ExtMsgBoxSet( 2, -1, $sBackColor)
	$iReturn = _ExtMsgBox(0, "CR32|MD4|MD5|SHA1|&ALL|Paste #",'CryptoCheck: ' & $sFileName & $sExtension, "Paste:      " & $sPaste & @CRLF & @CRLF & "CR32:" & @TAB & $sDataCR32 & @CRLF & "MD4:" & @TAB & $sDataMD4 & @CRLF & "MD5:" & @TAB & $sDataMD5 & @CRLF & "SHA1:     " & $sDataSHA1)
	Switch $iReturn
		Case -13
			_Encrypt(@GUI_DragFile)
			_PathSplit(@GUI_DragFile, $sDrive, $sDir, $sFileName, $sExtension) ; wird für Anzeige Dateiname im GUI-Titel benötigt
		Case 1
			ClipPut($sDataCR32)
		Case 2
			ClipPut($sDataMD4)
		Case 3
			ClipPut($sDataMD5)
		Case 4
			ClipPut($sDataSHA1)
		Case 5
			ClipPut("CR32:" & @TAB & $sDataCR32 & @CRLF & "MD4:" & @TAB & $sDataMD4 & @CRLF & "MD5:" & @TAB & $sDataMD5 & @CRLF & "SHA1:" & @TAB & $sDataSHA1)
		Case 6
			$sPaste = _StringIsHex(StringUpper(ClipGet()))
	EndSwitch
Until $iReturn = 0

Exit

#region - Funcs
Func _Encrypt($sFile)
	; CRC32:
	$hTimer = TimerInit()

	$sDataCR32 = _CRC32ForFile($sFile)
	$iTimer = TimerDiff($hTimer)

	ConsoleWrite("> CRC32 took " & $iTimer & " ms" & @CRLF)
	ConsoleWrite("Result: " & $sDataCR32 & @CRLF & @CRLF)
	; MD4:
	$hTimer = TimerInit()

	$sDataMD4 = _MD4ForFile($sFile)
	$iTimer = TimerDiff($hTimer)

	ConsoleWrite("+ MD4 took " & $iTimer & " ms" & @CRLF)
	ConsoleWrite("Result: " & $sDataMD4 & @CRLF & @CRLF)
	; MD5:
	$hTimer = TimerInit()

	$sDataMD5 = _MD5ForFile($sFile)
	$iTimer = TimerDiff($hTimer)

	ConsoleWrite("- MD5 took " & $iTimer & " ms" & @CRLF)
	ConsoleWrite("Result: " & $sDataMD5 & @CRLF & @CRLF)
	; SHA1:
	$hTimer = TimerInit()

	$sDataSHA1 = _SHA1ForFile($sFile)
	$iTimer = TimerDiff($hTimer)

	ConsoleWrite("! SHA1 took " & $iTimer & " ms" & @CRLF)
	ConsoleWrite("Result: " & $sDataSHA1 & @CRLF & @CRLF)
EndFunc

Func _BackColor()
	Local $sGruen = "0x00FF00"
	Local $sRot = "0xFF0000"
	If $sPaste = "" Then
		Return Default
	Else
		If $sPaste = $sDataCR32 Then Return $sGruen
		If $sPaste = $sDataMD4 Then Return $sGruen
		If $sPaste = $sDataMD5 Then Return $sGruen
		If $sPaste = $sDataSHA1 Then Return $sGruen
	EndIf
	Return $sRot
EndFunc

Func _StringIsHex($sHex)
	Local $sPasteTemp = $sHex
	$sHex = _HexToString($sHex) ; prüft, ob der Clipboard-Inhalt tatsächlich eine Checksum sein könnte
	If StringLeft( $sHex, 2) = "0x" Then $sPasteTemp = ""
	Return $sPasteTemp
EndFunc


; #FUNCTION# ;===============================================================================
;
; Name...........: _CRC32ForFile
; Description ...: Calculates CRC32 value for the specific file.
; Syntax.........: _CRC32ForFile ($sFile)
; Parameters ....: $sFile - Full path to the file to process.
; Return values .: Success - Returns CRC32 value in form of hex string
;                          - Sets @error to 0
;                  Failure - Returns empty string and sets @error:
;                  |1 - CreateFile function or call to it failed.
;                  |2 - CreateFileMapping function or call to it failed.
;                  |3 - MapViewOfFile function or call to it failed.
;                  |4 - RtlComputeCrc32 function or call to it failed.
; Author ........: trancexx
;
;==========================================================================================
Func _CRC32ForFile($sFile)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFileW", _
            "wstr", $sFile, _
            "dword", 0x80000000, _ ; GENERIC_READ
            "dword", 3, _ ; FILE_SHARE_READ|FILE_SHARE_WRITE
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _ ; SECURITY_ANONYMOUS
            "ptr", 0)

    If @error Or $a_hCall[0] = -1 Then
        Return SetError(1, 0, "")
    EndIf

    Local $hFile = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "CreateFileMappingW", _
            "hwnd", $hFile, _
            "dword", 0, _ ; default security descriptor
            "dword", 2, _ ; PAGE_READONLY
            "dword", 0, _
            "dword", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
        Return SetError(2, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)

    Local $hFileMappingObject = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "MapViewOfFile", _
            "hwnd", $hFileMappingObject, _
            "dword", 4, _ ; FILE_MAP_READ
            "dword", 0, _
            "dword", 0, _
            "dword", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(3, 0, "")
    EndIf

    Local $pFile = $a_hCall[0]
    Local $iBufferSize = FileGetSize($sFile)

    Local $a_iCall = DllCall("ntdll.dll", "dword", "RtlComputeCrc32", _
            "dword", 0, _
            "ptr", $pFile, _
            "int", $iBufferSize)

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(4, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)

    Local $iCRC32 = $a_iCall[0]

    Return SetError(0, 0, Hex($iCRC32))

EndFunc   ;==>_CRC32ForFile


; #FUNCTION# ;===============================================================================
;
; Name...........: _MD4ForFile
; Description ...: Calculates MD4 value for the specific file.
; Syntax.........: _MD4ForFile ($sFile)
; Parameters ....: $sFile - Full path to the file to process.
; Return values .: Success - Returns MD4 value in form of hex string
;                          - Sets @error to 0
;                  Failure - Returns empty string and sets @error:
;                  |1 - CreateFile function or call to it failed.
;                  |2 - CreateFileMapping function or call to it failed.
;                  |3 - MapViewOfFile function or call to it failed.
;                  |4 - MD4Init function or call to it failed.
;                  |5 - MD4Update function or call to it failed.
;                  |6 - MD4Final function or call to it failed.
; Author ........: trancexx
;
;==========================================================================================
Func _MD4ForFile($sFile)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFileW", _
            "wstr", $sFile, _
            "dword", 0x80000000, _ ; GENERIC_READ
            "dword", 3, _ ; FILE_SHARE_READ|FILE_SHARE_WRITE
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _ ; SECURITY_ANONYMOUS
            "ptr", 0)

    If @error Or $a_hCall[0] = -1 Then
        Return SetError(1, 0, "")
    EndIf

    Local $hFile = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "CreateFileMappingW", _
            "hwnd", $hFile, _
            "dword", 0, _ ; default security descriptor
            "dword", 2, _ ; PAGE_READONLY
            "dword", 0, _
            "dword", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
        Return SetError(2, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)

    Local $hFileMappingObject = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "MapViewOfFile", _
            "hwnd", $hFileMappingObject, _
            "dword", 4, _ ; FILE_MAP_READ
            "dword", 0, _
            "dword", 0, _
            "dword", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(3, 0, "")
    EndIf

    Local $pFile = $a_hCall[0]
    Local $iBufferSize = FileGetSize($sFile)

    Local $tMD4_CTX = DllStructCreate("dword i[2];" & _
            "dword buf[4];" & _
            "ubyte in[64];" & _
            "ubyte digest[16]")

    DllCall("advapi32.dll", "none", "MD4Init", "ptr", DllStructGetPtr($tMD4_CTX))

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(4, 0, "")
    EndIf

    DllCall("advapi32.dll", "none", "MD4Update", _
            "ptr", DllStructGetPtr($tMD4_CTX), _
            "ptr", $pFile, _
            "dword", $iBufferSize)

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(5, 0, "")
    EndIf

    DllCall("advapi32.dll", "none", "MD4Final", "ptr", DllStructGetPtr($tMD4_CTX))

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(6, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)

    Local $sMD4 = Hex(DllStructGetData($tMD4_CTX, "digest"))

    Return SetError(0, 0, $sMD4)

EndFunc   ;==>_MD4ForFile


; #FUNCTION# ;===============================================================================
;
; Name...........: _MD5ForFile
; Description ...: Calculates MD5 value for the specific file.
; Syntax.........: _MD5ForFile ($sFile)
; Parameters ....: $sFile - Full path to the file to process.
; Return values .: Success - Returns MD5 value in form of hex string
;                          - Sets @error to 0
;                  Failure - Returns empty string and sets @error:
;                  |1 - CreateFile function or call to it failed.
;                  |2 - CreateFileMapping function or call to it failed.
;                  |3 - MapViewOfFile function or call to it failed.
;                  |4 - MD5Init function or call to it failed.
;                  |5 - MD5Update function or call to it failed.
;                  |6 - MD5Final function or call to it failed.
; Author ........: trancexx
;
;==========================================================================================
Func _MD5ForFile($sFile)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFileW", _
            "wstr", $sFile, _
            "dword", 0x80000000, _ ; GENERIC_READ
            "dword", 3, _ ; FILE_SHARE_READ|FILE_SHARE_WRITE
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _ ; SECURITY_ANONYMOUS
            "ptr", 0)

    If @error Or $a_hCall[0] = -1 Then
        Return SetError(1, 0, "")
    EndIf

    Local $hFile = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "CreateFileMappingW", _
            "hwnd", $hFile, _
            "dword", 0, _ ; default security descriptor
            "dword", 2, _ ; PAGE_READONLY
            "dword", 0, _
            "dword", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
        Return SetError(2, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)

    Local $hFileMappingObject = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "MapViewOfFile", _
            "hwnd", $hFileMappingObject, _
            "dword", 4, _ ; FILE_MAP_READ
            "dword", 0, _
            "dword", 0, _
            "dword", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(3, 0, "")
    EndIf

    Local $pFile = $a_hCall[0]
    Local $iBufferSize = FileGetSize($sFile)

    Local $tMD5_CTX = DllStructCreate("dword i[2];" & _
            "dword buf[4];" & _
            "ubyte in[64];" & _
            "ubyte digest[16]")

    DllCall("advapi32.dll", "none", "MD5Init", "ptr", DllStructGetPtr($tMD5_CTX))

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(4, 0, "")
    EndIf

    DllCall("advapi32.dll", "none", "MD5Update", _
            "ptr", DllStructGetPtr($tMD5_CTX), _
            "ptr", $pFile, _
            "dword", $iBufferSize)

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(5, 0, "")
    EndIf

    DllCall("advapi32.dll", "none", "MD5Final", "ptr", DllStructGetPtr($tMD5_CTX))

    If @error Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(6, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)

    Local $sMD5 = Hex(DllStructGetData($tMD5_CTX, "digest"))

    Return SetError(0, 0, $sMD5)

EndFunc   ;==>_MD5ForFile


; #FUNCTION# ;===============================================================================
;
; Name...........: _SHA1ForFile
; Description ...: Calculates SHA1 value for the specific file.
; Syntax.........: _SHA1ForFile ($sFile)
; Parameters ....: $sFile - Full path to the file to process.
; Return values .: Success - Returns SHA1 value in form of hex string
;                          - Sets @error to 0
;                  Failure - Returns empty string and sets @error:
;                  |1 - CreateFile function or call to it failed.
;                  |2 - CreateFileMapping function or call to it failed.
;                  |3 - MapViewOfFile function or call to it failed.
;                  |4 - CryptAcquireContext function or call to it failed.
;                  |5 - CryptCreateHash function or call to it failed.
;                  |6 - CryptHashData function or call to it failed.
;                  |7 - CryptGetHashParam function or call to it failed.
; Author ........: trancexx
;
;==========================================================================================
Func _SHA1ForFile($sFile)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFileW", _
            "wstr", $sFile, _
            "dword", 0x80000000, _ ; GENERIC_READ
            "dword", 3, _ ; FILE_SHARE_READ|FILE_SHARE_WRITE
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _ ; SECURITY_ANONYMOUS
            "ptr", 0)

    If @error Or $a_hCall[0] = -1 Then
        Return SetError(1, 0, "")
    EndIf

    Local $hFile = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "CreateFileMappingW", _
            "hwnd", $hFile, _
            "dword", 0, _ ; default security descriptor
            "dword", 2, _ ; PAGE_READONLY
            "dword", 0, _
            "dword", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
        Return SetError(2, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)

    Local $hFileMappingObject = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "MapViewOfFile", _
            "hwnd", $hFileMappingObject, _
            "dword", 4, _ ; FILE_MAP_READ
            "dword", 0, _
            "dword", 0, _
            "dword", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(3, 0, "")
    EndIf

    Local $pFile = $a_hCall[0]
    Local $iBufferSize = FileGetSize($sFile)

    Local $a_iCall = DllCall("advapi32.dll", "int", "CryptAcquireContext", _
            "ptr*", 0, _
            "ptr", 0, _
            "ptr", 0, _
            "dword", 1, _ ; PROV_RSA_FULL
            "dword", 0xF0000000) ; CRYPT_VERIFYCONTEXT

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(4, 0, "")
    EndIf

    Local $hContext = $a_iCall[1]

    $a_iCall = DllCall("advapi32.dll", "int", "CryptCreateHash", _
            "ptr", $hContext, _
            "dword", 0x00008004, _ ; CALG_SHA1
            "ptr", 0, _ ; nonkeyed
            "dword", 0, _
            "ptr*", 0)

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        DllCall("advapi32.dll", "int", "CryptReleaseContext", "ptr", $hContext, "dword", 0)
        Return SetError(5, 0, "")
    EndIf

    Local $hHashSHA1 = $a_iCall[5]

    $a_iCall = DllCall("advapi32.dll", "int", "CryptHashData", _
            "ptr", $hHashSHA1, _
            "ptr", $pFile, _
            "dword", $iBufferSize, _
            "dword", 0)

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        DllCall("advapi32.dll", "int", "CryptDestroyHash", "ptr", $hHashSHA1)
        DllCall("advapi32.dll", "int", "CryptReleaseContext", "ptr", $hContext, "dword", 0)
        Return SetError(6, 0, "")
    EndIf

    Local $tOutSHA1 = DllStructCreate("byte[20]")

    $a_iCall = DllCall("advapi32.dll", "int", "CryptGetHashParam", _
            "ptr", $hHashSHA1, _
            "dword", 2, _ ; HP_HASHVAL
            "ptr", DllStructGetPtr($tOutSHA1), _
            "dword*", 20, _
            "dword", 0)

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        DllCall("advapi32.dll", "int", "CryptDestroyHash", "ptr", $hHashSHA1)
        DllCall("advapi32.dll", "int", "CryptReleaseContext", "ptr", $hContext, "dword", 0)
        Return SetError(7, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)

    DllCall("advapi32.dll", "int", "CryptDestroyHash", "ptr", $hHashSHA1)

    Local $sSHA1 = Hex(DllStructGetData($tOutSHA1, 1))

    DllCall("advapi32.dll", "int", "CryptReleaseContext", "ptr", $hContext, "dword", 0)

    Return SetError(0, 0, $sSHA1)

EndFunc   ;==>_SHA1ForFile
#endregion - Funcs