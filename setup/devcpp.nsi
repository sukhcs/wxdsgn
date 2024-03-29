;--------------------------------
; $Id: devcpp.nsi 1460 2012-01-29 02:22:24Z tbreina $
; Author: Tony Reina
; LGPL license
; NSIS Install Script for wx-devcpp
; http://nsis.sourceforge.net/

; NOTE: You'll need to get the INTEC plugin (http://nsis.sourceforge.net/Inetc_plug-in)
;  for the web download section. Just copy the intec.dll into your NSIS plugins directory.

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "Sections.nsh"
  !include "logiclib.nsh" ; needed by ${switch}, ${IF}, {$ELSEIF}
  !include "EnvVarUpdate.nsh" ; Updates the path environment variable
  !include "WordFunc.nsh"  ; For VersionCompare
;--------------------------------

!define WXDEVCPP_VERSION "7.4.2"
!define IDE_DEVPAK_NAME  "wxdevcpp.DevPak"
!define PROGRAM_TITLE "wxDev-C++"
!define PROGRAM_NAME "wxdevcpp"
!define EXECUTABLE_NAME "devcpp.exe"
!define DEFAULT_START_MENU_DIRECTORY "wxDev-C++"

!define MSVC_VERSION "10.0" ; 2005 = version 8.0, 2008 = version 9.0, 2010 = version 10.0
!define MSVC_YEAR "2010"
!define DOWNLOAD_URL "http://downloads.sourceforge.net/project/wxdsgn/devpaks/"  ; Url of devpak server for downloads
!define HAVE_MINGW
!define HAVE_MSVC
;!define  DONT_INCLUDE_DEVPAKS ; Don't include the devpaks in the installer package
                               ; Instead we'll rely on an internet connection
                               ; and download the devpaks from our update server
!define wxWidgets_name "wxWidgets"
!define YES  "Yes"
!define NO "No"


!ifdef HAVE_MINGW

  !define wxWidgets_mingw_devpak "${wxWidgets_name}_gcc.DevPak" ; name of the wxWidgets Mingw gcc devpak
  
!endif

!ifdef HAVE_MSVC

  !define wxWidgets_msvc_devpak "${wxWidgets_name}_vc.DevPak" ; name of the wxWidgets MS VC devpak
 
!endif

!define wxWidgetsCommon_devpak "${wxWidgets_name}_common.DevPak"  ; name of the common includes devpak
!define wxWidgetsSamples_devpak "${wxWidgets_name}_samples.DevPak"  ; name of the samples devpak

; Variable declarations
Var LOCAL_APPDATA
Var Have_Internet

; FindINIStr
; Courtesy of Zinthose (http://forums.winamp.com/showthread.php?t=336325)
; Finds a field within an ini file based on the value of another field
!define FindINIStr '!insertmacro _FindINIStr'
!macro _FindINIStr _OutVar _INIFileName _MatchName _MatchValue _ReadValue
    ;${FindINIStr} $0 $INIfilename 'LocalFileName=Language.DevPak' 'Version'
    
    Push `${_ReadValue}`
    Push `${_MatchValue}`
    Push `${_MatchName}`
    Push `${_INIFileName}`
    Call FindINIStr
    Pop ${_OutVar}
!macroend

Function FindINIStr
    # Stack:  _INIFileName _MatchName _MatchValue _ReadValue
    Exch $0 ; r0 _MatchName _MatchValue _ReadValue

    IfFileExists $0 0 FileNotFound

    Exch    ; _MatchName r0 _MatchValue _ReadValue
    Exch $1 ; r1 r0 _MatchValue _ReadValue
    Exch 2  ; _MatchValue r0 r1 _ReadValue
    Exch $2 ; r2 r0 r1 _ReadValue
    Exch 3  ; _ReadValue r0 r1 r2
    Exch $3 ; r3 r0 r1 r2
    Push $4 ; r4 r3 r0 r1 r2
    Push $5 ; r5 r4 r3 r0 r1 r2
    Push $6 ; r6 r5 r4 r3 r0 r1 r2
    Push $7 ; r7 r6 r5 r4 r3 r0 r1 r2
    Push $8 ; r8 r7 r6 r5 r4 r3 r0 r1 r2
    Push $9 ; r9 r8 r7 r6 r5 r4 r3 r0 r1 r2

    ; $0 = _INIFileName
    ; $1 = _MatchName
    ; $2 = _MatchValue
    ; $3 = _ReadValue
    ; $4 = StrBuffer
    ; $5 = RC / Max
    ; $6 = Offset
    ; $7 = Temp
    ; $8 = Temp
    ; $9 = ReturnValue

    ## Allocate Memory
        System::Alloc ${NSIS_MAX_STRLEN}
        Pop $4

    ## Get INI Section Names from file
        System::Call 'Kernel32::GetPrivateProfileSectionNames(i r4,i ${NSIS_MAX_STRLEN},t r0)i .r5'
        ## WARNING ASSUMTIONS MADE HERE

        StrCpy $6 0
        StrCpy $9 ""
        Loop:
            IntCmp $5 $6 NoMoreSections NoMoreSections
            System::Call '*$4(&v$6,&t${NSIS_MAX_STRLEN} .r7)'
            StrLen $8 $7
            IntOp $6 $6 + $8
            IntOp $6 $6 + 1
            ReadINIStr $8 $0 $7 $1
            StrCmp $8 $2 0 Loop
            ReadINIStr $9 $0 $7 $3
        NoMoreSections:
        StrCmp $9 "" 0 +2
            SetErrors

    System::Free $4

    ## Restore The Stack
        ;STACK:   r9 r8 r7 r6 r5 r4 r3 r0 r1 r2
        Exch $9 ; _RetVar r8 r7 r6 r5 r4 r3 r0 r1 r2
        Exch 9  ; r2 r8 r7 r6 r5 r4 r3 r0 r1 _RetVar
        Pop $2  ; r8 r7 r6 r5 r4 r3 r0 r1 _RetVar
        Pop $8  ; r7 r6 r5 r4 r3 r0 r1 _RetVar
        Pop $7  ; r6 r5 r4 r3 r0 r1 _RetVar
        Pop $6  ; r5 r4 r3 r0 r1 _RetVar
        Pop $5  ; r4 r3 r0 r1 _RetVar
        Pop $4  ; r3 r0 r1 _RetVar
        Pop $3  ; r0 r1 _RetVar
        Pop $0  ; r1 _RetVar
        Pop $1  ; _RetVar
    Return
    FileNotFound:
        Pop $0
        Push ""
        MessageBox MB_OK "File not found!"
        SetErrors
FunctionEnd

; ================================================
; MACRO - ReplaceSubStr
; This script is derived of a script Written by dirtydingus :
; "Another String Replace (and Slash/BackSlash Converter)"
;
; for more information please see :
; http://nsis.sourceforge.net/Another_String_Replace_(and_Slash/BackSlash_Converter)

Var MODIFIED_STR

!macro ReplaceSubStr OLD_STR SUB_STR REPLACEMENT_STR

	Push "${OLD_STR}" ;String to do replacement in (haystack)
	Push "${SUB_STR}" ;String to replace (needle)
	Push "${REPLACEMENT_STR}" ; Replacement
	Call StrRep
	Pop $R0 ;result
	StrCpy $MODIFIED_STR $R0

!macroend

; ================================================
; MACRO - InstallDevPak
!macro InstallDevPak DEVPAK_NAME
; Installs a wxDev-C++ devpak using the devpak manager
; NOTE: Filenames with spaces in them seem to screw up the download
;  I think the NSISdl cant handle spaces in the url. So DevPaks with
;   names like "How to Program in wxDev-C++.DevPak" won't work with
;   this macro without the ReplaceSubStr macro to replace spaces with %20

  SetOutPath $INSTDIR\Packages
  
  DetailPrint "Installing ${DEVPAK_NAME}"
  
  ; NSISdl downloader doesn't like urls with spaces in them. We'll use a string replace function to
  ;      replace spaces with %20
  !insertmacro ReplaceSubStr "${DEVPAK_NAME}" " " "%20" ; Replace any spaces with %20 for correct url
  ; NOTE: DevPak for Url is now stored in variable MODIFIED_STR

!ifdef DONT_INCLUDE_DEVPAKS ; If we don't include them here, we'll need to download them at install time

${IF} $Have_Internet == ${NO}
MessageBox MB_ICONEXCLAMATION  "Sorry, but this version of the installer requires an internet connection.$\r$\nAborting installation"
Quit

${ELSE}
DetailPrint "Url: ${DOWNLOAD_URL}$MODIFIED_STR"
inetc::get /RESUME "Connection interrupted. Resume?" "${DOWNLOAD_URL}$MODIFIED_STR" "$INSTDIR\Packages\${DEVPAK_NAME}" /END
Pop $R0 ;Get the return value

${IF} $R0 != "OK"
    MessageBox MB_OK "Download failed: return = $R0"
    Abort   ; Abort the installation
${ENDIF}

${ENDIF}

!else   ;We have included devpaks, but user can still check for updates if desired

${IF} $Have_Internet == ${YES}

${FindINIStr} $0 '$INSTDIR\Packages\webupdate.conf' 'LocalFilename' '${DEVPAK_NAME}' 'Version'
${FindINIStr} $1 '$INSTDIR\Packages\webupdate_server.conf' 'LocalFilename' '${DEVPAK_NAME}' 'Version'

${VersionCompare} $0 $1 $R0  ; Check which version is newer 0 = same, 1 = first is newer; 2 = second is newer

${IF} $R0 == '2'  ; server devpak is newer

DetailPrint "Upgrading ${DEVPAK_NAME} from version $0 to version $1 via webupdate"
inetc::get /RESUME "Connection interrupted. Resume?" "${DOWNLOAD_URL}$MODIFIED_STR" "$INSTDIR\Packages\${DEVPAK_NAME}" /END
Pop $R0 ;Get the return value

${IF} $R0 != "OK"
    MessageBox MB_OK "Download failed: return = $R0"
    Abort   ; Abort the installation
${ENDIF}

${ELSE}  ; server is same or older (that would be strange, huh?)

File "Packages\${DEVPAK_NAME}"   ; Copy the devpak over -- NOTE: We assume the devpak is located within the Packages subdirectory when we build the installer

${ENDIF}

${ELSE}  ; server is same or older (that would be strange, huh?)

File "Packages\${DEVPAK_NAME}"   ; Copy the devpak over -- NOTE: We assume the devpak is located within the Packages subdirectory when we build the installer

${ENDIF}

!endif

  ; Replace .DevPak extension with .entry so that we can uninstall a previous devpak
  !insertmacro ReplaceSubStr "${DEVPAK_NAME}" ".DevPak" ".entry"
  ; Now uninstall the previous devpak
  ExecWait '"$INSTDIR\packman.exe" /auto /quiet /uninstall "$INSTDIR\Packages\$MODIFIED_STR"'

  ExecWait '"$INSTDIR\packman.exe" /auto /quiet /install "$INSTDIR\Packages\${DEVPAK_NAME}"'
  Delete  "$INSTDIR\Packages\${DEVPAK_NAME}"
  SetOutPath $INSTDIR
  DetailPrint "${DEVPAK_NAME} installed"
  
!macroend

# [Installer Attributes]

!ifdef HAVE_MINGW
!ifdef DONT_INCLUDE_DEVPAKS ; If we don't include them here, we'll need to download them at install time
OutFile "${PROGRAM_NAME}_webbased_setup.exe"
!define DISPLAY_NAME "${PROGRAM_TITLE} Web-based Installer"
!else
OutFile "${PROGRAM_NAME}_${WXDEVCPP_VERSION}_full_setup.exe"
!define DISPLAY_NAME "${PROGRAM_TITLE} ${WXDEVCPP_VERSION}"
!endif
!else
OutFile "${PROGRAM_NAME}_${WXDEVCPP_VERSION}_nomingw_setup.exe"
!endif

Name "${DISPLAY_NAME}"
Caption "${DISPLAY_NAME}"

# [Licence Attributes]
LicenseText "${PROGRAM_TITLE} is distributed under the GNU General Public License :"
LicenseData "license.txt"

# [Directory Selection]
InstallDir "$PROGRAMFILES\Dev-Cpp"
DirText "Select the directory to install ${PROGRAM_TITLE} to :"

# [Additional Installer Settings ]
SetCompress force
;SetCompressor lzma

;--------------------------------
;Interface Settings

ShowInstDetails show
AutoCloseWindow false
SilentInstall normal
CRCCheck on
SetCompress auto
SetDatablockOptimize on
RequestExecutionLevel admin
;SetOverwrite ifnewer
XPStyle on

!ifdef DONT_INCLUDE_DEVPAKS ; If we don't include devpaks, then don't print the required disk space
SpaceTexts none
!endif

InstType "Full" ;1
InstType "Minimal IDE with visual designer" ;2
InstType "IDE without visual designer" ;3

ComponentText "Choose components"

# [Background Gradient]
BGGradient off

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "wxdevcpp.bmp" ; use our IDE's icon
!define MUI_ABORTWARNING

;--------------------------------

  Var STARTMENU_FOLDER

  !define MUI_COMPONENTSPAGE_SMALLDESC

  !insertmacro MUI_PAGE_LICENSE "license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  
  !define MUI_STARTMENUPAGE_DEFAULTFOLDER ${DEFAULT_START_MENU_DIRECTORY}
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER

  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !define MUI_FINISHPAGE_RUN "$INSTDIR\${EXECUTABLE_NAME}"
  
  ;!define MUI_FINISHPAGE_NOREBOOTSUPPORT
  ;!insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages - Commented out languages are not currently supported by NSIS

  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "Bulgarian"
  !insertmacro MUI_LANGUAGE "Catalan"
  ;!insertmacro MUI_LANGUAGE "Chinese"
  ;!insertmacro MUI_LANGUAGE "Chinese_TC"
  !insertmacro MUI_LANGUAGE "Croatian"
  !insertmacro MUI_LANGUAGE "Czech"
  !insertmacro MUI_LANGUAGE "Danish"
  !insertmacro MUI_LANGUAGE "Dutch"
  !insertmacro MUI_LANGUAGE "Estonian"
  !insertmacro MUI_LANGUAGE "French"
  ;!insertmacro MUI_LANGUAGE "Galego"
  !insertmacro MUI_LANGUAGE "German"
  !insertmacro MUI_LANGUAGE "Greek"
  !insertmacro MUI_LANGUAGE "Hungarian"
  !insertmacro MUI_LANGUAGE "Italian"
  !insertmacro MUI_LANGUAGE "Korean"
  !insertmacro MUI_LANGUAGE "Latvian"
  !insertmacro MUI_LANGUAGE "Norwegian"
  !insertmacro MUI_LANGUAGE "Polish"
  !insertmacro MUI_LANGUAGE "Portuguese"
  !insertmacro MUI_LANGUAGE "Romanian"
  !insertmacro MUI_LANGUAGE "Russian"
  !insertmacro MUI_LANGUAGE "Slovak"
  !insertmacro MUI_LANGUAGE "Slovenian"
  !insertmacro MUI_LANGUAGE "Spanish"
  ;!insertmacro MUI_LANGUAGE "SpanishCastellano"
  !insertmacro MUI_LANGUAGE "Swedish"
  !insertmacro MUI_LANGUAGE "Turkish"
  !insertmacro MUI_LANGUAGE "Ukrainian"

;--------------------------------
;Reserve Files

  ;If you are using solid compression, files that are required before
  ;the actual installation should be stored first in the data block,
  ;because this will make your installer start faster.

  !insertmacro MUI_RESERVEFILE_LANGDLL

;--------------------------------
;Installer Sections

Section "${PROGRAM_TITLE} program files (required)" SectionMain
  SectionIn 1 2 3 RO
  SetOutPath $INSTDIR
 
 Call IsInternetAvailable  ; Check to see if we have an internet connection
 
!ifdef DONT_INCLUDE_DEVPAKS ; We need an internet connection if we don't include the devpaks in the installation package
        ${IF} $Have_Internet == ${NO}
        MessageBox MB_ICONEXCLAMATION  "Sorry, but this version of the installer requires an internet connection.$\r$\nAborting installation"
        Quit
        ${ENDIF}
!endif

 ; Internet download of devpaks
 ; NSIS can download the devpaks from our project's webupdate server
 ; This way the installer can always be up-to-date.
 ; Let's first ask the user whether they want to try to download the latest
 ; devpaks. If not, then we'll just use the devpaks we incorporated into
 ; the installer.
  MessageBox MB_YESNO "Do you want to try to download the latest devpaks (requires internet connection)?" IDYES AnswerYes
     StrCpy $Have_Internet ${NO}    ; no internet connection or no download wanted
   AnswerYes:
 
 ; Download the webupdate.conf file from server to determine what version of devpaks lives there.
 !ifndef DONT_INCLUDE_DEVPAKS
SetOutPath $INSTDIR\Packages
File "Packages\webupdate.conf"  ; Grab the ini file for the devpak versions we have in this installer

${IF} $Have_Internet == ${YES}
DetailPrint "Getting webupdate file: Url= ${DOWNLOAD_URL}webupdate.conf"
inetc::get /SILENT /RESUME "Connection interrupted. Resume?" "${DOWNLOAD_URL}webupdate.conf" "$INSTDIR\Packages\webupdate_server.conf" /END
Pop $R0 ;Get the return value

${IF} $R0 != "OK"
   MessageBox MB_OK "Download failed for webupdate.conf on internet server:$\r$\nreturn = $R0.$\r$\nFalling back to the included installer devpaks instead."
   DetailPrint "No internet connection found. Using devpaks included from installer instead."
   StrCpy $Have_Internet ${NO}    ; no internet connection or no download wanted
${ENDIF}
${ENDIF}

!endif

SetOutPath $INSTDIR

 ; We just need the license and the Package Manager files.
 ; All other files are contained within devpaks and will be installed by the pakman
  File "packman.exe"
  

  ; Find all installed wxWidgets devpaks and uninstall them
  FindFirst $0 $1 $INSTDIR\Packages\*wxWidgets*.entry
loop_devpaks:
  StrCmp $1 "" done_uninstalldevpaks
  DetailPrint 'Uninstalling package $1'
  ExecWait '"$INSTDIR\packman.exe" /auto /quiet /uninstall "$INSTDIR\Packages\$1"'
  FindNext $0 $1
  Goto loop_devpaks
done_uninstalldevpaks:

; Ok, now we should have successfully uninstalled all previously-installed devpaks.

; Install the main IDE devpaks
; We're installing most of the files by using the Package Manager
; This will help us keep tabs on things and make upgrades easier.
; In fact, the InstallDevPak directory can be setup to download a devpak
; if a local version is not available.

File "license.txt"

; Check for MinGW
Call CheckMinGW

 SetOutPath $INSTDIR\Lang
  ; Basic English language file
  File "Lang\English.lng"
  File "Lang\English.tips"

  ; Install wxDev-C++ executable
!insertmacro InstallDevPak "${IDE_DEVPAK_NAME}"

  ; Install Dev-C++ examples
  !insertmacro InstallDevPak "devcpp_examples.DevPak"

  ; Install Dev-C++ examples
  !insertmacro InstallDevPak "Templates.DevPak"

  ; On Windows Vista, delete a previous virtual path
  Delete "$LOCAL_APPDATA\VirtualStore\Program Files\Dev-Cpp\*.*"

  ; Delete old devcpp.map to avoid confusion in bug reports
  Delete "$INSTDIR\devcpp.map"

  SetOutPath $INSTDIR

SectionEnd

SectionGroup /e "wxWidgets" SectionGroupwxWidgetsMain

Section "RAD Visual Designer" SectionwxDesigner
  SectionIn 1 2

; Install the wxdsgn visual designer plugin
  !insertmacro InstallDevPak "wxdsgn.DevPak"

SectionEnd

Section "wxWidgets common files" SectionwxWidgetsCommon
  SectionIn 1 2

  !insertmacro InstallDevPak ${wxWidgetsCommon_devpak}

SectionEnd

!ifdef HAVE_MINGW
;SectionGroup /e "Mingw gcc wxWidgets" SectionGroupwxWidgetsGCC

Section "MinGW gcc libraries" SectionwxWidgetsMingw

  SectionIn 1 2
  
  !insertmacro InstallDevPak ${wxWidgets_mingw_devpak}
  
SectionEnd

;SectionGroupEnd
!endif

!ifdef HAVE_MSVC

;SectionGroup /e "MS VC++ ${MSVC_YEAR} wxWidgets" SectionGroupwxWidgetsMSVC

Section /o "MS VC++ ${MSVC_YEAR} libraries" SectionwxWidgetsMSVC

  SectionIn 1

  !insertmacro InstallDevPak ${wxWidgets_msvc_devpak}
  
SectionEnd

;SectionGroupEnd

!endif

Section "Samples" SectionwxWidgetsSamples

  SectionIn 1

  !insertmacro InstallDevPak ${wxWidgetsSamples_devpak}
  
SectionEnd

SectionGroupEnd  ; SectionGroupwxWidgetsMain

SectionGroup /e "Help files" SectionGroupHelp

Section "${PROGRAM_TITLE} help" SectionHelp

  SectionIn 1 2 3 RO
  
; Install wxDevCpp Help Files
  !insertmacro InstallDevPak "DevCppHelp.DevPak"
  SetOutPath $INSTDIR

SectionEnd

Section /o "Sof.T's ${PROGRAM_TITLE} Book" SectionWxBook

  SectionIn 1 2

  ; Install SofT's wxDev-C++ programming book
  !insertmacro InstallDevPak "Programming with wxDev-C++.DevPak"

  SetOutPath $INSTDIR
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\${PROGRAM_TITLE} Book.lnk" "$INSTDIR\Help\Programming with wxDev-C++.pdf"
  
  ; Install the custom help file menu for the IDE
  SetOutPath $APPDATA\Dev-Cpp
  File "additional\Help\devhelp.ini"
  
SectionEnd

SectionGroupEnd

Section "Icon files" SectionIcons
  SectionIn 1 2 3
  SetOutPath $INSTDIR\Icons
  File "Icons\*.ico"

  SetOutPath $INSTDIR

SectionEnd

Section "Language files" SectionLangs
  SectionIn 1
  
  !insertmacro InstallDevPak "Language.DevPak"
  
  SetOutPath $INSTDIR
  
SectionEnd

# [File association]
SubSection "Associate C and C++ files to ${PROGRAM_TITLE}" SectionAssocs

Section "Associate .dev files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".dev"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".dev" "" "${PROGRAM_NAME}.dev"
  WriteRegStr HKCR "${PROGRAM_NAME}.dev" "" "${PROGRAM_TITLE} Project File"
  WriteRegStr HKCR "${PROGRAM_NAME}.dev\DefaultIcon" "" '$0,3'
  WriteRegStr HKCR "${PROGRAM_NAME}.dev\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .c files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".c"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".c" "" "${PROGRAM_NAME}.c"
  WriteRegStr HKCR "${PROGRAM_NAME}.c" "" "C Source File"
  WriteRegStr HKCR "${PROGRAM_NAME}.c\DefaultIcon" "" '$0,4'
  WriteRegStr HKCR "${PROGRAM_NAME}.c\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .cpp files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".cpp"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".cpp" "" "${PROGRAM_NAME}.cpp"
  WriteRegStr HKCR "${PROGRAM_NAME}.cpp" "" "C++ Source File"
  WriteRegStr HKCR "${PROGRAM_NAME}.cpp\DefaultIcon" "" '$0,5'
  WriteRegStr HKCR "${PROGRAM_NAME}.cpp\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .h files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".h"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".h" "" "${PROGRAM_NAME}.h"
  WriteRegStr HKCR "${PROGRAM_NAME}.h" "" "C Header File"
  WriteRegStr HKCR "${PROGRAM_NAME}.h\DefaultIcon" "" '$0,6'
  WriteRegStr HKCR "${PROGRAM_NAME}.h\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .hpp files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".hpp"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".hpp" "" "${PROGRAM_NAME}.hpp"
  WriteRegStr HKCR "${PROGRAM_NAME}.hpp" "" "C++ Header File"
  WriteRegStr HKCR "${PROGRAM_NAME}.hpp\DefaultIcon" "" '$0,7'
  WriteRegStr HKCR "${PROGRAM_NAME}.hpp\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .rc files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".rc"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".rc" "" "${PROGRAM_NAME}.rc"
  WriteRegStr HKCR "${PROGRAM_NAME}.rc" "" "Resource Source File"
  WriteRegStr HKCR "${PROGRAM_NAME}.rc\DefaultIcon" "" '$0,8'
  WriteRegStr HKCR "${PROGRAM_NAME}.rc\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .DevPak files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".DevPak"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  StrCpy $1 $INSTDIR\PackMan.exe
  WriteRegStr HKCR ".DevPak" "" "${PROGRAM_NAME}.devpak"
  WriteRegStr HKCR "${PROGRAM_NAME}.devpak" "" "${PROGRAM_TITLE} Package File"
  WriteRegStr HKCR "${PROGRAM_NAME}.devpak\DefaultIcon" "" '$0,9'
  WriteRegStr HKCR "${PROGRAM_NAME}.devpak\Shell\Open\Command" "" '$1 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .devpackage files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".devpackage"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  StrCpy $1 $INSTDIR\PackMan.exe
  WriteRegStr HKCR ".devpackage" "" "${PROGRAM_NAME}.devpackage"
  WriteRegStr HKCR "${PROGRAM_NAME}.devpackage" "" "${PROGRAM_TITLE} Package File"
  WriteRegStr HKCR "${PROGRAM_NAME}.devpackage\DefaultIcon" "" '$0,10'
  WriteRegStr HKCR "${PROGRAM_NAME}.devpackage\Shell\Open\Command" "" '$1 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

Section "Associate .template files to ${PROGRAM_TITLE}"
  SectionIn 1 2 3

  StrCpy $0 ".template"
  Call BackupAssoc

  StrCpy $0 $INSTDIR\${EXECUTABLE_NAME}
  WriteRegStr HKCR ".template" "" "${PROGRAM_NAME}.template"
  WriteRegStr HKCR "${PROGRAM_NAME}.template" "" "${PROGRAM_TITLE} Template File"
  WriteRegStr HKCR "${PROGRAM_NAME}.template\DefaultIcon" "" '$0,1'
  WriteRegStr HKCR "${PROGRAM_NAME}.template\Shell\Open\Command" "" '$0 "%1"'
  Call RefreshShellIcons
  
  SetOutPath $INSTDIR
  
SectionEnd

SubSectionEnd

Section "Create Quick Launch shortcut" SectionQuickLaunch
  SectionIn 1 2 3
  SetShellVarContext current
  CreateShortCut "$QUICKLAUNCH\${PROGRAM_TITLE}.lnk" "$INSTDIR\${EXECUTABLE_NAME}"
  
  SetOutPath $INSTDIR
  
SectionEnd


Section "Remove all previous configuration files" SectionConfig
   SectionIn 1 2 3

SetShellVarContext current
  ;Delete "$APPDATA\Dev-Cpp\*.*"
  Delete "$APPDATA\Dev-Cpp\devcpp.ini"
  Delete "$APPDATA\Dev-Cpp\devcpp.cfg"
  Delete "$APPDATA\Dev-Cpp\cache.ccc"
  Delete "$APPDATA\Dev-Cpp\defaultcode.cfg"
  Delete "$APPDATA\Dev-Cpp\devshortcuts.cfg"
  Delete "$APPDATA\Dev-Cpp\classfolders.dcf"
  Delete "$APPDATA\Dev-Cpp\mirrors.cfg"
  Delete "$APPDATA\Dev-Cpp\tools.ini"
  Delete "$APPDATA\Dev-Cpp\devcpp.ci"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.ini"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.cfg"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.ci"

SetShellVarContext all
  ;Delete "$APPDATA\Dev-Cpp\*.*"

  Delete "$APPDATA\Dev-Cpp\devcpp.ini"
  Delete "$APPDATA\Dev-Cpp\devcpp.cfg"
  Delete "$APPDATA\Dev-Cpp\cache.ccc"
  Delete "$APPDATA\Dev-Cpp\defaultcode.cfg"
  Delete "$APPDATA\Dev-Cpp\devshortcuts.cfg"
  Delete "$APPDATA\Dev-Cpp\classfolders.dcf"
  Delete "$APPDATA\Dev-Cpp\mirrors.cfg"
  Delete "$APPDATA\Dev-Cpp\tools.ini"
  Delete "$APPDATA\Dev-Cpp\devcpp.ci"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.ini"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.cfg"
  Delete "$APPDATA\Dev-Cpp\wxdevcpp.ci"

  Call GetLocalAppData
  Delete "$LOCAL_APPDATA\devcpp.ini"
  Delete "$LOCAL_APPDATA\devcpp.cfg"
  Delete "$LOCAL_APPDATA\cache.ccc"
  Delete "$LOCAL_APPDATA\defaultcode.cfg"
  Delete "$LOCAL_APPDATA\devshortcuts.cfg"
  Delete "$LOCAL_APPDATA\classfolders.dcf"
  Delete "$LOCAL_APPDATA\mirrors.cfg"
  Delete "$LOCAL_APPDATA\tools.ini"
  Delete "$LOCAL_APPDATA\devcpp.ci"
  Delete "$LOCAL_APPDATA\wxdevcpp.ini"
  Delete "$LOCAL_APPDATA\wxdevcpp.cfg"
  Delete "$LOCAL_APPDATA\wxdevcpp.ci"

SetShellVarContext current

  Delete "$APPDATA\devcpp.ini"
  Delete "$APPDATA\devhelp.ini"
  Delete "$APPDATA\devcpp.cfg"
  Delete "$APPDATA\cache.ccc"
  Delete "$APPDATA\defaultcode.cfg"
  Delete "$APPDATA\devshortcuts.cfg"
  Delete "$APPDATA\classfolders.dcf"
  Delete "$APPDATA\mirrors.cfg"
  Delete "$APPDATA\tools.ini"
  Delete "$APPDATA\devcpp.ci"
  Delete "$APPDATA\wxdevcpp.ini"
  Delete "$APPDATA\wxdevcpp.cfg"
  Delete "$APPDATA\wxdevcpp.ci"

SetShellVarContext all

  Delete "$APPDATA\devcpp.ini"
  Delete "$APPDATA\devhelp.ini"
  Delete "$APPDATA\devcpp.cfg"
  Delete "$APPDATA\cache.ccc"
  Delete "$APPDATA\defaultcode.cfg"
  Delete "$APPDATA\devshortcuts.cfg"
  Delete "$APPDATA\classfolders.dcf"
  Delete "$APPDATA\mirrors.cfg"
  Delete "$APPDATA\tools.ini"
  Delete "$APPDATA\devcpp.ci"
  Delete "$APPDATA\wxdevcpp.ini"
  Delete "$APPDATA\wxdevcpp.cfg"
  Delete "$APPDATA\wxdevcpp.ci"

  Delete "$INSTDIR\devcpp.ini"
  Delete "$INSTDIR\devhelp.ini"
  Delete "$INSTDIR\devcpp.cfg"
  Delete "$INSTDIR\cache.ccc"
  Delete "$INSTDIR\defaultcode.cfg"
  Delete "$INSTDIR\devshortcuts.cfg"
  Delete "$INSTDIR\classfolders.dcf"
  Delete "$INSTDIR\mirrors.cfg"
  Delete "$INSTDIR\tools.ini"
  Delete "$INSTDIR\devcpp.ci"
  Delete "$INSTDIR\wxdevcpp.ini"
  Delete "$INSTDIR\wxdevcpp.cfg"
  Delete "$INSTDIR\wxdevcpp.ci"

  SetOutPath $INSTDIR

SectionEnd

;--------------------------------

# [Sections' descriptions (on mouse over)]
  LangString TEXT_IO_SUBTITLE ${LANG_ENGLISH} "Compiler Selection for ${PROGRAM_TITLE}"

  LangString DESC_SectionMain ${LANG_ENGLISH} "The ${PROGRAM_TITLE} IDE (Integrated Development Environment), package manager and templates"
  
   LangString DESC_SectionGroupwxWidgetsMain ${LANG_ENGLISH} "wxWidgets"

  LangString DESC_SectionwxWidgetsCommon ${LANG_ENGLISH} "wxWidgets common include files. All compilers use these files."

  LangString DESC_SectionwxDesigner ${LANG_ENGLISH} "RAD Visual Designer for wxWidgets GUIs"

!ifdef HAVE_MINGW
  LangString DESC_SectionGroupwxWidgetsGCC ${LANG_ENGLISH} "wxWidgets for Mingw gcc"
  LangString DESC_SectionwxWidgetsMingw ${LANG_ENGLISH} "wxWidgets libraries compiled with Mingw gcc"
  LangString DESC_SectionMingw ${LANG_ENGLISH} "The MinGW gcc compiler and associated tools, headers and libraries"
  
!endif
!ifdef HAVE_MSVC
  LangString DESC_SectionGroupwxWidgetsMSVC ${LANG_ENGLISH} "wxWidgets for MS VC++ ${MSVC_YEAR}"
  LangString DESC_SectionwxWidgetsMSVC ${LANG_ENGLISH} "wxWidgets libraries compiled with MS VC ${MSVC_YEAR}"
  
!endif

  LangString DESC_SectionwxWidgetsSamples ${LANG_ENGLISH} "wxWidgets samples directory"
  
  LangString DESC_SectionGroupHelp ${LANG_ENGLISH} "Documentation for ${PROGRAM_TITLE}"
  LangString DESC_SectionHelp ${LANG_ENGLISH} "Help on using ${PROGRAM_TITLE} and programming in C"
  LangString DESC_SectionWxBook ${LANG_ENGLISH} "Sof.T's book on using ${PROGRAM_TITLE} and programming in C/C++"
  LangString DESC_SectionIcons ${LANG_ENGLISH} "Various icons that you can use in your programs"

  LangString DESC_SectionLangs ${LANG_ENGLISH} "The ${PROGRAM_TITLE} interface translated to different languages (other than English which is built-in)"
  LangString DESC_SectionAssocs ${LANG_ENGLISH} "Use ${PROGRAM_TITLE} as the default application for opening these types of files"
  LangString DESC_SectionShortcuts ${LANG_ENGLISH} "Create a '${PROGRAM_TITLE}' program group with shortcuts, in the start menu"
  LangString DESC_SectionQuickLaunch ${LANG_ENGLISH} "Create a shortcut to ${PROGRAM_TITLE} in the QuickLaunch toolbar"
  LangString DESC_SectionDebug ${LANG_ENGLISH} "Debug file to help debugging ${PROGRAM_TITLE}"
  LangString DESC_SectionConfig ${LANG_ENGLISH} "Remove all previous configuration files"

  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionMain} $(DESC_SectionMain)
    
!insertmacro MUI_DESCRIPTION_TEXT ${SectionwxDesigner} $(DESC_SectionwxDesigner)
     !insertmacro MUI_DESCRIPTION_TEXT ${SectionwxWidgetsCommon} $(DESC_SectionwxWidgetsCommon)

!ifdef HAVE_MINGW
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionGroupwxWidgetsGCC} $(DESC_SectionGroupwxWidgetsGCC)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionwxWidgetsMingw} $(DESC_SectionwxWidgetsMingw)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionMingw} $(DESC_SectionMingw)
!endif
!ifdef HAVE_MSVC
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionGroupwxWidgetsMSVC} $(DESC_SectionGroupwxWidgetsMSVC)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionwxWidgetsMSVC} $(DESC_SectionwxWidgetsMSVC)
!endif

    !insertmacro MUI_DESCRIPTION_TEXT ${SectionGroupwxWidgetsExamples} $(DESC_SectionGroupwxWidgetsExamples)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionwxWidgetsSamples} $(DESC_SectionwxWidgetsSamples)
    
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionGroupHelp} $(DESC_SectionGroupHelp)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionHelp} $(DESC_SectionHelp)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionWxBook} $(DESC_SectionWxBook)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionIcons} $(DESC_SectionIcons)

    !insertmacro MUI_DESCRIPTION_TEXT ${SectionLangs} $(DESC_SectionLangs)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionAssocs} $(DESC_SectionAssocs)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionShortcuts} $(DESC_SectionShortcuts)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionQuickLaunch} $(DESC_SectionQuickLaunch)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionDebug} $(DESC_SectionDebug)
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionConfig} $(DESC_SectionConfig)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------

; Functions
Function .onInstSuccess

!ifndef DONT_INCLUDE_DEVPAKS
;
;  Remove the webupdate.conf files
;
   Delete $INSTDIR\Packages\webupdate.conf
   Delete $INSTDIR\Packages\webupdate_server.conf
   
!endif

; If the installation was successful, then let's write to the registry

; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\${PROGRAM_NAME} "Install_Dir" "$INSTDIR"

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}" "DisplayName" "${PROGRAM_TITLE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

; Add links to START MENU
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  ;try to read from registry if last installation installed for All Users/Current User
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" \
      "Shortcuts"
  StrCmp $0 "" cont CurrentUsers
  cont:

  SetShellVarContext current
  MessageBox MB_YESNO "Do you want to install ${PROGRAM_TITLE} for all users on this computer ?" IDNO CurrentUsers

AllUsers:
  SetShellVarContext all

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" \
      "Shortcuts" "$0"
      
  ;ReadEnvStr $1 PATH
  ;DetailPrint "Original path = $1"
  
  ;${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\bin"   ; Prepend to path
  ;ReadEnvStr $1 PATH
  ;DetailPrint "Modified path = $1"

CurrentUsers:

  SetShellVarContext current

  ;ReadEnvStr $1 PATH
  ;DetailPrint "Original path = $1"
  
  ;${EnvVarUpdate} $0 "PATH" "P" "HKCU" "$INSTDIR\bin"   ; Prepend to path
  
  ;ReadEnvStr $1 PATH
  ;DetailPrint "Modified path = $1"

  StrCpy $0 "$SMPROGRAMS\$STARTMENU_FOLDER"

  CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
  SetOutPath $INSTDIR
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\${PROGRAM_TITLE}.lnk" "$INSTDIR\${EXECUTABLE_NAME}"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Update ${PROGRAM_TITLE}.lnk" "$INSTDIR\updater.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\License.lnk" "$INSTDIR\license.txt"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall ${PROGRAM_TITLE}.lnk" "$INSTDIR\uninstall.exe"

!insertmacro MUI_STARTMENU_WRITE_END

FunctionEnd


!ifdef HAVE_MSVC
Function .onSelChange

   Call CheckMSVC ; Check to see if we've selected to install wxWidgets devpak with MS VC++

FunctionEnd
!endif

;called when the uninstall was successful
Function un.onUninstSuccess
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  
  ;${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"   ; Remove from path
  ;${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" "$INSTDIR\bin"   ; Remove from path

FunctionEnd

;backup file association
Function BackupAssoc
  ;$0 is an extension - for example ".dev"

  ;check if backup already exists
  ReadRegStr $1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" "$0"
  ;don't backup if backup exists in registry
  StrCmp $1 "" 0 no_assoc

  ReadRegStr $1 HKCR "$0" ""
  ;don't backup dev-cpp associations
  StrCmp $1 "DevCpp$0" no_assoc

  StrCmp $1 "" no_assoc
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" "$0" "$1"
  no_assoc:
  
FunctionEnd

;restore file association
Function un.RestoreAssoc
  ;$0 is an extension - for example ".dev"

  DeleteRegKey HKCR "$0"
  ReadRegStr $1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" "$0"
  ${IF} $1 != ""
    WriteRegStr HKCR "$0" "" "$1"
    Call un.RefreshShellIcons
  ${ENDIF}
  
FunctionEnd

;http://nsis.sourceforge.net/archive/viewpage.php?pageid=202
;After changing file associations, you can call this macro to refresh the shell immediatly. 
;It calls the shell32 function SHChangeNotify. This will force windows to reload your changes from the registry.
!define SHCNE_ASSOCCHANGED 0x08000000
!define SHCNF_IDLIST 0

Function RefreshShellIcons
  ; By jerome tremblay - april 2003
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
  (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function un.RefreshShellIcons
  ; By jerome tremblay - april 2003
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
  (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

!ifdef HAVE_MSVC
#Check to see if user wants the MS VC++ devpak. If so, message box to remind him to download the SDK and compiler
Function CheckMSVC

  SectionGetFlags ${SectionwxWidgetsMSVC} $R0  ; Is wxWidgetsMSVC section is checked?
  IntOp $R0 $R0 & ${SF_SELECTED}
  IntCmp $R0 ${SF_SELECTED} detectvc

  Abort

detectvc:    ; Try to detect the MS VC compiler
 
  ; VS C++ Free Version
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\${MSVC_VERSION}\Setup\VS" "MSMDir"
  IfErrors 0 detectsdk   ; If it's detected, then we probably don't need to remind user to install it.

  ; VS C++ Enterprise Version
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\${MSVC_VERSION}\Setup\VS" "ProductDir"
  IfErrors 0 detectsdk   ; If it's detected, then we probably don't need to remind user to install it.

  Goto show
  
detectsdk:    ; Try to detect the MS SDK
  ;ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\SxS\FrameworkSDK" "8.0"
  ;IfErrors 0 dontshow  ; If it's detected, then we probably don't need to remind user to install it.

  ;ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\SxS\FrameworkSDK" "7.1"
  ;IfErrors 0 dontshow   ; If it's detected, then we probably don't need to remind user to install it.
  Goto dontshow
  
show:
  ;Remind user to download and install MS VC++ and the MS SDK
  MessageBox MB_OK|MB_ICONINFORMATION "You've selected to install the wxWidgets MS VC++ ${MSVC_YEAR} devpak.$\r$\n\
             If you have the MS VC++ ${MSVC_YEAR} compiler and MS SDK installed, then please continue.$\r$\n\
             If not, then please download and install before you install ${PROGRAM_TITLE}.$\r$\n\
             You can find them at the official Microsoft website.$\r$\n\
             http://msdn.microsoft.com/vstudio/express/visualc/"

dontshow:

FunctionEnd
!endif

#Fill the global variable with Local\Application Data directory CSIDL_LOCAL_APPDATA
!define CSIDL_LOCAL_APPDATA 0x001C
Function GetLocalAppData
  StrCpy $0 ${NSIS_MAX_STRLEN}

  System::Call 'shfolder.dll::SHGetFolderPathA(i, i, i, i, t) i \
                (0, ${CSIDL_LOCAL_APPDATA}, 0, 0, .r0) .r1'
  
  StrCpy $LOCAL_APPDATA $0
FunctionEnd

Function un.GetLocalAppData
  StrCpy $0 ${NSIS_MAX_STRLEN}

  System::Call 'shfolder.dll::SHGetFolderPathA(i, i, i, i, t) i \
                (0, ${CSIDL_LOCAL_APPDATA}, 0, 0, .r0) .r1'
  
  StrCpy $LOCAL_APPDATA $0
FunctionEnd

;--------------------------------

# [UnInstallation]

UninstallText "This program will uninstall ${PROGRAM_TITLE}. Continue ?"
ShowUninstDetails show
RequestExecutionLevel admin

Section "Uninstall"

  ; Remove files and uninstaller
  Delete "$INSTDIR\uninstall.exe"
  !include ".\installed_files.nsh"

  ; Remove icons
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}\Backup" \
     "Shortcuts"
     
  ; Determine if the STARUP_MENU DIRECTORY was created during install
  ${IF} $0 != "" 

  Delete "$0\${PROGRAM_TITLE}.lnk"
  Delete "$0\License.lnk"
  Delete "$0\Uninstall ${PROGRAM_TITLE}.lnk"
  RMDir  "$0"
 ${ENDIF}

  SetShellVarContext current
  Delete "$QUICKLAUNCH\${PROGRAM_TITLE}.lnk"

  ; Restore file associations
  StrCpy $0 ".dev"
  Call un.RestoreAssoc
  StrCpy $0 ".c"
  Call un.RestoreAssoc
  StrCpy $0 ".cpp"
  Call un.RestoreAssoc
  StrCpy $0 ".h"
  Call un.RestoreAssoc
  StrCpy $0 ".hpp"
  Call un.RestoreAssoc
  StrCpy $0 ".rc"
  Call un.RestoreAssoc
  StrCpy $0 ".devpak"
  Call un.RestoreAssoc
  StrCpy $0 ".devpackage"
  Call un.RestoreAssoc
  StrCpy $0 ".template" 
  Call un.RestoreAssoc
 
  DeleteRegKey HKCR "${PROGRAM_NAME}.dev"
  DeleteRegKey HKCR "${PROGRAM_NAME}.c"
  DeleteRegKey HKCR "${PROGRAM_NAME}.cpp"
  DeleteRegKey HKCR "${PROGRAM_NAME}.h"
  DeleteRegKey HKCR "${PROGRAM_NAME}.hpp"
  DeleteRegKey HKCR "${PROGRAM_NAME}.rc"
  DeleteRegKey HKCR "${PROGRAM_NAME}.devpak"
  DeleteRegKey HKCR "${PROGRAM_NAME}.devpackage"
  DeleteRegKey HKCR "${PROGRAM_NAME}.template"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}"
  DeleteRegKey HKLM "SOFTWARE\${PROGRAM_NAME}"

  MessageBox MB_YESNO "Do you want to remove all the remaining configuration files?" IDNO Done

SetShellVarContext all
  Delete "$APPDATA\Dev-Cpp\*.*"
  
  SetShellVarContext current
  Delete "$APPDATA\Dev-Cpp\*.*"
  
  call un.GetLocalAppData
  Delete "$LOCAL_APPDATA\devcpp.ini"
  Delete "$LOCAL_APPDATA\devhelp.ini"
  Delete "$LOCAL_APPDATA\devcpp.cfg"
  Delete "$LOCAL_APPDATA\cache.ccc"
  Delete "$LOCAL_APPDATA\defaultcode.cfg"
  Delete "$LOCAL_APPDATA\devshortcuts.cfg"
  Delete "$LOCAL_APPDATA\classfolders.dcf"
  Delete "$LOCAL_APPDATA\mirrors.cfg"
  Delete "$LOCAL_APPDATA\tools.ini"
  Delete "$LOCAL_APPDATA\devcpp.ci"

SetShellVarContext all
  Delete "$APPDATA\devcpp.ini"
  Delete "$APPDATA\devhelp.ini"
  Delete "$APPDATA\devcpp.cfg"
  Delete "$APPDATA\cache.ccc"
  Delete "$APPDATA\defaultcode.cfg"
  Delete "$APPDATA\devshortcuts.cfg"
  Delete "$APPDATA\classfolders.dcf"
  Delete "$APPDATA\mirrors.cfg"
  Delete "$APPDATA\tools.ini"
  Delete "$APPDATA\devcpp.ci"
  Delete "$APPDATA\wxdevcpp.ci"
  Delete "$APPDATA\wxdevcpp.ini"
  Delete "$APPDATA\wxdevcpp.cfg"
  
  SetShellVarContext current
  Delete "$APPDATA\devcpp.ini"
  Delete "$APPDATA\devhelp.ini"
  Delete "$APPDATA\devcpp.cfg"
  Delete "$APPDATA\cache.ccc"
  Delete "$APPDATA\defaultcode.cfg"
  Delete "$APPDATA\devshortcuts.cfg"
  Delete "$APPDATA\classfolders.dcf"
  Delete "$APPDATA\mirrors.cfg"
  Delete "$APPDATA\tools.ini"
  Delete "$APPDATA\devcpp.ci"
  Delete "$APPDATA\wxdevcpp.ci"
  Delete "$APPDATA\wxdevcpp.ini"
  Delete "$APPDATA\wxdevcpp.cfg"
  
  Delete "$INSTDIR\devcpp.ini"
  Delete "$INSTDIR\devhelp.ini"
  Delete "$INSTDIR\devcpp.cfg"
  Delete "$INSTDIR\cache.ccc"
  Delete "$INSTDIR\defaultcode.cfg"
  Delete "$INSTDIR\devshortcuts.cfg"
  Delete "$INSTDIR\classfolders.dcf"
  Delete "$INSTDIR\mirrors.cfg"
  Delete "$INSTDIR\tools.ini"
  Delete "$INSTDIR\devcpp.ci"

Done:
  MessageBox MB_OK "${PROGRAM_TITLE} has been uninstalled.$\r$\nPlease now delete the $INSTDIR directory if it doesn't contain some of your documents"

SectionEnd

# Determine if we have an internet connection
# If we do, then we can download the latest devpaks from the website.
Function IsInternetAvailable

  Push $R0

    ClearErrors
    Dialer::AttemptConnect
    IfErrors noie3

    Pop $R0
    StrCmp $R0 "online" connected

!ifdef DONT_INCLUDE_DEVPAKS
      MessageBox MB_OK|MB_ICONSTOP "Cannot connect to the internet."
!endif

    noie3:

    ; IE3 not installed
    MessageBox MB_OK|MB_ICONINFORMATION "Please connect to the internet now."
    StrCpy $Have_Internet ${NO}
    
    connected:
    StrCpy $Have_Internet ${YES}
  Pop $R0

FunctionEnd

Function .onInit

  ;try to read from registry if there's a current version and run its uninstall
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}" \
      "UninstallString"
  ${IF} $0 != ""   ; A previous install was found

     MessageBox MB_YESNO "A previous version of ${PROGRAM_TITLE} is installed.$\r$\nShould I uninstall it now?" IDNO NoUninstall1
     ; If yes, then run the previous uninstaller
     ExecWait '$0'
     NoUninstall1:

  ${ENDIF}
  
  ; Do the same for Dev-C++
  ;try to read from registry if there's a current version and run its uninstall
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\devcpp" \
      "UninstallString"
  ${IF} $0 != ""   ; A previous install was found

     MessageBox MB_YESNO "A previous version of Dev-C++/wxDev-C++ is installed.$\r$\nShould I uninstall it now?" IDNO NoUninstall2
     ; If yes, then run the previous uninstaller
     ExecWait '$0'
     NoUninstall2:

  ${ENDIF}

FunctionEnd

#Check to see if user has MinGW installed. 
Function CheckMinGW

  ;ClearErrors

  ; MinGW 
 ; ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC2C1BDB-1E91-4F94-B99C-E716FE2E9C75}_is1" "InstallLocation"
 ; DetailPrint $0
  ;IfErrors 0 mingwInstalled   ; If it's detected, then we probably don't need to remind user to install it.

  ClearErrors
  
  ; TDM-GCC MinGW
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TDM-GCC" "InstallLocation"
  DetailPrint $0
  IfErrors mingwNotInstalled mingwInstalled   ; If it's detected, then we probably don't need to remind user to install it.

mingwNotInstalled:
;====================================================================
; Install TDM-GCC MinGW using their installer so that we can always
;  update to latest version via them.

MessageBox MB_OK "TDM-GCC MinGW (http://tdm-gcc.tdragon.net/) was not detected.$\r$\nStarting its installer for use with ${PROGRAM_TITLE}.$\r$\nClick OK to continue."

!ifdef DONT_INCLUDE_DEVPAKS

  File "tdm-gcc-webdl.exe"   ; Web access version
  ExecWait "$INSTDIR\tdm-gcc-webdl.exe"
  Delete "$INSTDIR\tdm-gcc-webdl.exe"

!else

  File "tdm-gcc-4.6.1.exe"
  ExecWait "$INSTDIR\tdm-gcc-4.6.1.exe"
  Delete "$INSTDIR\tdm-gcc-4.6.1.exe"

!endif
;====================================================================

mingwInstalled:
  DetailPrint "MinGW installed."

FunctionEnd

