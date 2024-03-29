///-------------------------------------------------------------
///
/// @file        PackMan2ExtendedFrm.h
/// @author      Tony Reina / Edward Toovey (Sof.T)
/// Created:     3/18/2008 1:46:40 PM
/// @section DESCRIPTION
///          PackMan2ExtendedFrm class declaration
/// @section LICENSE  wxWidgets license
/// @version $Id: PackMan2ExtendedFrm.h 1290 2009-09-16 23:58:56Z tbreina $
///-------------------------------------------------------------

#ifndef __PACKMAN2EXTENDEDFRM_h__
#define __PACKMAN2EXTENDEDFRM_h__

#ifdef __BORLANDC__
#pragma hdrstop
#endif

#ifndef WX_PRECOMP
#include <wx/wx.h>
#include <wx/frame.h>
#else
#include <wx/wxprec.h>
#endif

//Do not add custom headers between
//Header Include Start and Header Include End.
//wxDev-C++ designer will remove them. Add custom headers after the block.
////Header Include Start
#include <wx/listbox.h>
#include <wx/menu.h>
#include <wx/statusbr.h>
#include <wx/listctrl.h>
#include <wx/textctrl.h>
#include <wx/stattext.h>
#include <wx/panel.h>
#include <wx/notebook.h>
#include <wx/aui/aui.h>
////Header Include End
#include <wx/aui/aui.h>
#include <wx/aui/auibook.h>
#include <vector>
#include "InstallDevPak.h"

////Dialog Style Start
#undef PackMan2ExtendedFrm_STYLE
#define PackMan2ExtendedFrm_STYLE wxCAPTION | wxRESIZE_BORDER | wxSYSTEM_MENU | wxMINIMIZE_BOX | wxCLOSE_BOX
////Dialog Style End

class PackMan2ExtendedFrm : public wxFrame
{
private:
    DECLARE_EVENT_TABLE();

public:
    PackMan2ExtendedFrm(wxWindow *parent, wxWindowID id = 1, const wxString &title = wxT("PackMan2Extended"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxDefaultSize, long style = PackMan2ExtendedFrm_STYLE);
    virtual ~PackMan2ExtendedFrm();
    void UpdatePackageList();
    void WxToolBar1Menu(wxCommandEvent& event);
    void lstPackagesSelected(wxListEvent& event);
    void ActionShowDetails(wxCommandEvent& event);
    void ActionShowToolbar(wxCommandEvent& event);
    void MnuReloadDatabaseClick(wxCommandEvent& event);
    void btnVerifyUpdateUI(wxUpdateUIEvent& event);
    void ActionVerifyUpdateUI(wxUpdateUIEvent& event);

    void edtUrlClickUrl(wxTextUrlEvent& event);
private:
    //Do not add custom control declarations between
    //GUI Control Declaration Start and GUI Control Declaration End.
    //wxDev-C++ will remove them. Add custom code after the block.
    ////GUI Control Declaration Start
    wxListBox *WxPackageInstalledFiles;
    wxAuiManager *DockManager;
    wxMenuBar *WxMenuBar1;
    wxStatusBar *WxStatusBar1;
    wxListCtrl *lstPackages;
    wxListBox *lstFiles;
    wxStaticText *WebsiteLabel;
    wxTextCtrl *edtUrl;
    wxTextCtrl *mmoPackageDescription;
    wxStaticText *WxStaticText3;
    wxTextCtrl *edtPackageVersion;
    wxStaticText *WxStaticText2;
    wxTextCtrl *edtPackageName;
    wxStaticText *WxStaticText1;
    wxPanel *WxNoteBookPage2;
    wxAuiNotebook *nbkPackageDetails;
    wxAuiToolBar *WxToolBar1;
    ////GUI Control Declaration End

    int selectedPackage;
    std::vector<DevPakInfo> entryInfo;  // STL vector to store the devpak info

private:
    //Note: if you receive any error with these enum IDs, then you need to
    //change your old form code that are based on the #define control IDs.
    //#defines may replace a numeric value for the enum names.
    //Try copy and pasting the below block in your old form header files.
    enum
    {
        ////GUI Enum Control ID Start
        ID_WXPACKAGEINSTALLEDFILES = 7005,
        ID_MNU_FILE_1001 = 1001,
        ID_MNU_INSTALLPACKAGE_1002 = 1002,
        ID_MNU_VERIFYFILES_1003 = 1003,
        ID_MNU_DELETEPACKAGE_1004 = 1004,
        ID_MNU_RELOADDATABASE_1028 = 1028,
        ID_MNU_EXIT_1010 = 1010,
        ID_MNU_DETAILS_CTRL_D_1031 = 1031,
        ID_MNU_SUBMENUITEM17_1033 = 1033,
        ID_MNU_HELP_1005 = 1005,
        ID_MNU_HELP_1030 = 1030,
        ID_MNU_ABOUT_1006 = 1006,

        ID_WXSTATUSBAR1 = 1036,
        ID_LSTPACKAGES = 3003,
        ID_LSTFILES = 1057,
        ID_WEBSITELABEL = 7000,
        ID_EDTURL = 6000,
        ID_MMOPACKAGEDESCRIPTION = 1054,
        ID_WXSTATICTEXT3 = 1053,
        ID_EDTPACKAGEVERSION = 1052,
        ID_WXSTATICTEXT2 = 1051,
        ID_EDTPACKAGENAME = 1050,
        ID_WXSTATICTEXT1 = 1049,
        ID_WXNOTEBOOKPAGE2 = 1048,
        ID_NBKPACKAGEDETAILS = 3000,
        ID_BTNEXIT = 5000,
        ID_BTNABOUT = 5003,
        ID_BTNHELP = 5005,
        ID_BTNREMOVE = 5007,
        ID_BTNVERIFY = 5009,
        ID_BTNINSTALL = 5011,
        ID_WXTOOLBAR1 = 2001,
        ////GUI Enum Control ID End
        ID_DUMMY_VALUE_ //don't remove this value unless you have other enum values
    };

private:
    void OnClose(wxCloseEvent& event);
    void CreateGUIControls();
    void ActionShowHelp(wxCommandEvent& event);
    void ActionShowAbout(wxCommandEvent& event);
    void ActionRemovePackage(wxCommandEvent& event);
    void ActionInstallPackage(wxCommandEvent& event);
    void ActionVerifyPackage(wxCommandEvent& event);
    void ActionExit(wxCommandEvent& event);
    void ActionRemoveUpdate(wxUpdateUIEvent &event);
    void ActionShowDetailsUpdate(wxUpdateUIEvent &event);
    void ActionShowToolbarUpdate(wxUpdateUIEvent &event);
};

#endif
