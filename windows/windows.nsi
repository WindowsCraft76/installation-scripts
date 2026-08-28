; NSIS installer - Windows

!include MUI2.nsh
!include nsDialogs.nsh
!include LogicLib.nsh
!include WordFunc.nsh
!include FileFunc.nsh

; -------------------------
; Configuration
; -------------------------

!define DISPLAY_NAME "Name"
!define APP_NAME "Name"
!define COMPANY_NAME "Company"
!define Year "2000"
!define DISPLAY_VERSION "v1.0.0r"
!define APP_VERSION "1.0.0"
!define SETUP_VERSION "1.0.0.0"
!define ARCHITECTURE "" ; x64 or arm64

!define SOURCE_DIR ""
!define LICENSE_FILE ""

Icon ""

Name "${DISPLAY_NAME} ${DISPLAY_VERSION}"
OutFile "${APP_NAME}Setup-${DISPLAY_VERSION}-${ARCHITECTURE}.exe"
InstallDir "$LOCALAPPDATA\Programs\${DISPLAY_NAME}"
!define REGKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

RequestExecutionLevel admin
Unicode true
SetCompressor /SOLID lzma
SetCompressorDictSize 64


; -------------------------
; Setup properties
; -------------------------

VIProductVersion "${SETUP_VERSION}"

VIAddVersionKey "ProductName" "${DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "${COMPANY_NAME}"
VIAddVersionKey "FileDescription" "Installer of ${DISPLAY_NAME}"
VIAddVersionKey "FileVersion" "${SETUP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright (c) ${Year} ${COMPANY_NAME}"


; -------------------------
; Variables
; -------------------------

Var INSTALLED_VERSION
Var INSTALLED_DIR
Var UPDATE_MODE
Var VERSION_RESULT


; -------------------------
; Pages
; -------------------------

; !define MUI_ICON ""
; !define MUI_WELCOMEFINISHPAGE_BITMAP ""

!define MUI_FINISHPAGE_RUN "${APP_NAME}.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch the game when closing the installer."
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create a desktop shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION DesktopShortcut
!define MUI_WELCOMEPAGE_TITLE "${DISPLAY_NAME} ${DISPLAY_VERSION}"

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfUpdateMode
!insertmacro MUI_PAGE_WELCOME

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfUpdateMode
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfUpdateMode
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfUpdateMode
!insertmacro MUI_PAGE_FINISH

Function .onInstSuccess

  ${If} $UPDATE_MODE == "1"
    MessageBox MB_ICONINFORMATION \
      "${DISPLAY_NAME} has been updated!"
    Abort
  ${EndIf}

FunctionEnd

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"
!insertmacro VersionCompare

Function SkipIfUpdateMode

  ${If} $UPDATE_MODE == "1"
    Abort
  ${EndIf}

FunctionEnd


; -------------------------
; StrContains
; -------------------------

Function StrContains

  Exch $R9
  Exch
  Exch $R8
  Push $R7
  Push $R6

  StrLen $R6 $R9
  StrLen $R7 $R8

  sc_loop:
    IntCmp $R7 0 sc_notfound sc_notfound
    StrCpy $R0 $R8 $R6
    StrCmp $R0 $R9 sc_found
    StrCpy $R8 $R8 "" 1
    IntOp $R7 $R7 - 1
    Goto sc_loop

  sc_found:
    StrCpy $R9 $R9
    Goto sc_done
  sc_notfound:
    StrCpy $R9 ""
  sc_done:

  Pop $R6
  Pop $R7
  Exch $R8
  Exch
  Exch $R9

FunctionEnd


; -------------------------
; Install
; -------------------------

Function .onInit

  ReadRegStr $INSTALLED_VERSION HKLM "${REGKEY}" "DisplayVersion"
  ReadRegStr $INSTALLED_DIR HKLM "${REGKEY}" "InstallLocation"

  ${If} $INSTALLED_VERSION == ""
    StrCpy $UPDATE_MODE "0"
    Return
  ${EndIf}

  ${VersionCompare} $INSTALLED_VERSION "${APP_VERSION}" $VERSION_RESULT

  ${If} $VERSION_RESULT == 0
    MessageBox MB_ICONINFORMATION \
      "You already have the latest version installed!"
    Abort
  ${EndIf}

  ${If} $VERSION_RESULT == 1
    MessageBox MB_ICONINFORMATION \
      "A newer version is already installed."
    Abort
  ${EndIf}

  StrCpy $UPDATE_MODE "1"

  MessageBox MB_ICONQUESTION|MB_YESNO \
    "Do you want to update ${DISPLAY_NAME} to ${DISPLAY_VERSION}?" \
    IDYES doUpdate
  Abort

  doUpdate:
    StrCpy $INSTDIR "$INSTALLED_DIR"

    nsExec::ExecToStack 'tasklist /FI "IMAGENAME eq ${APP_NAME}.exe" /NH /FO CSV'
    Pop $R0
    Pop $R1

    ${If} $R1 != ""
      Push $R1
      Push "${APP_NAME}.exe"
      Call StrContains
      Pop $R2
      ${If} $R2 != ""
        MessageBox MB_ICONSTOP "Please close ${DISPLAY_NAME} before updating it."
        Abort
      ${EndIf}
    ${EndIf}

FunctionEnd

Section "Install"

  ${If} $UPDATE_MODE == "1"
    RMDir /r "$INSTDIR"
    CreateDirectory "$INSTDIR"
  ${EndIf}

  SetOutPath "$INSTDIR"

  File /r "${SOURCE_DIR}\${ARCHITECTURE}\"
  File "${LICENSE_FILE}"

  CreateShortCut "$STARTMENU\Programs\${DISPLAY_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe"

  WriteUninstaller "$INSTDIR\uninstall.exe"
  Call WriteRegistry

SectionEnd

Function DesktopShortcut

  CreateShortCut "$DESKTOP\${DISPLAY_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe"

FunctionEnd


; -------------------------
; Registry
; -------------------------

Function WriteRegistry

  WriteRegStr HKLM "${REGKEY}" "DisplayName" "${DISPLAY_NAME}"
  WriteRegStr HKLM "${REGKEY}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "${REGKEY}" "Publisher" "${COMPANY_NAME}"
  WriteRegStr HKLM "${REGKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${REGKEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${REGKEY}" "DisplayIcon" "$INSTDIR\${APP_NAME}.exe"

FunctionEnd


; -------------------------
; Uninstall
; -------------------------
Function un.onInit

  nsExec::ExecToStack 'tasklist /FI "IMAGENAME eq ${APP_NAME}.exe" /NH /FO CSV'
  Pop $R0
  Pop $R1

  ${If} $R1 != ""
    Push $R1
    Push "${APP_NAME}.exe"
    Call un.StrContains
    Pop $R2
    ${If} $R2 != ""
      MessageBox MB_ICONSTOP "Please close ${DISPLAY_NAME} before uninstalling it."
      Abort
    ${EndIf}
  ${EndIf}

FunctionEnd

Function un.StrContains

  Exch $R9
  Exch
  Exch $R8
  Push $R7
  Push $R6

  StrLen $R6 $R9
  StrLen $R7 $R8

  loop:
    IntCmp $R7 0 notfound notfound
    StrCpy $R0 $R8 $R6
    StrCmp $R0 $R9 found
    StrCpy $R8 $R8 "" 1
    IntOp $R7 $R7 - 1
    Goto loop

  found:
    StrCpy $R9 $R9
    Goto done
  notfound:
    StrCpy $R9 ""
  done:

  Pop $R6
  Pop $R7
  Exch $R8
  Exch
  Exch $R9

FunctionEnd

Section "Uninstall"

  Delete "$DESKTOP\${DISPLAY_NAME}.lnk"
  Delete "$STARTMENU\Programs\${DISPLAY_NAME}.lnk"

  Delete "$INSTDIR\uninstall.exe"
  Delete "$INSTDIR\*.*"
  RMDir /r "$INSTDIR"

  DeleteRegKey HKLM "${REGKEY}"

SectionEnd
