### Tk app
#	Rename cyrillic files
###
set auto_path [linsert $auto_path 0 [file join . lib]]]

package require Tk
package require renameCyrToLatFilenames
package require properties

### Main frame
wm title . $properties::labelTitleWM
grid [ttk::frame .frMain -padding "3 3 12 12"] \
	-column 0 -row 0 -sticky nwes
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

### Text field and button to choose Directory
set fldPath [pwd]
grid [ttk::entry .frMain.fldPath -textvariable fldPath] \
	-column 0 -row 0 -columnspan 2 -sticky we
grid [ ttk::label .frMain.lblDirPath -text $properties::labelPathToDir] \
	-column 2 -row 0 -sticky w
grid [ttk::button .frMain.btnPath -text $properties::labelOpenDir -command setPath] \
	-column 3 -row 0 

### Checks recursion
grid [ttk::checkbutton .frMain.chckRecurs -text $properties::labelRecurs \
	-variable chckRecursVal -onvalue 1] \
		-column 0 -row 1 -columnspan 2 -sticky w
set chckRecursVal 1

### Checks is need to rename
grid [ttk::checkbutton .frMain.chckNeedRename -text $properties::labelNeedRename \
	-variable chckNeedRename -onvalue 1] \
		-column 2 -row 1 -sticky w
set chckNeedRename 0

### Checks is need to remove bak files ###
grid [ttk::checkbutton .frMain.chckNeedRemoveBaks -text $properties::labelNeedRemoveBaks \
	-variable chckNeedRemoveBaks -onvalue 1] \
		-column 0 -columnspan 2 -row 2 -sticky w
set chckNeedRemoveBaks 0

### Text field for file extensons
set fldExts $properties::fldExts
grid [ttk::entry .frMain.fldExts -textvariable fldExts] \
	-column 0 -row 3 -columnspan 2 -sticky we
grid [ttk::label .frMain.lblFileExts -text $properties::labelFileExts]	 \
	-column 2 -row 3 -sticky w


### Text area to set log output
set logOut [text .frMain.log -width 80 -height 12 -wrap none \
		-yscrollcommand {.frMain.yScroll set} \
		-state disabled]
set yscrollLog [scrollbar .frMain.yScroll -orient vertical -command {.frMain.log yview}]
		
grid $logOut -column 0 -row 4 -columnspan 3 -rowspan 2 -sticky we
grid $yscrollLog -column 2 -row 4 -rowspan 2 -sticky nse


### Button is started process
grid [ttk::button .frMain.btnRun -text $properties::labelStartProcess -command startProcess] \
	-column 3 -row 4 -sticky wes -rowspan 2


### Progress bar ###
grid [scale .frMain.progress \
    	-orient horizontal \
    	-sliderrelief flat \
	    -sliderlength 0 \
	    -troughcolor #AAAAAA \
	    -showvalue 0 \
	    -label $properties::labelProgress] -column 0 -row 6 -sticky we -columnspan 2


foreach w [winfo children .frMain] {
	grid configure $w -padx 5 -pady 5
}


focus .frMain.fldPath
bind . <Return> {startProcess}
bind . <Control-o> {setPath}
bind . <Key-Escape> {exit}
pack .frMain -fill both -expand 1

proc setPath {} {
	set ::fldPath [tk_chooseDirectory]
}

proc isPathValid {} {
	if {![info exists ::fldPath] || ![file exists $::fldPath]} {
		tk_messageBox -message $properties::messageWrongPath \
			-icon error -title Error
		return false
	}
	return true
}

proc startProcess {} {
	if {[isPathValid]} {
		.frMain.log configure -state normal
		set params [dict create \
						PATH_DIR $::fldPath \
						LOG_WIN .frMain.log \
						CHCK_RECURS $::chckRecursVal \
						CHCK_RENAME $::chckNeedRename \
						CHCK_REMOVE_BAK $::chckNeedRemoveBaks \
						EXTS $::fldExts \
						PROGRESS .frMain.progress
					]
		::renameCyrToLatFilenames::startProcess $params
		.frMain.log configure -state disabled
	}
}
