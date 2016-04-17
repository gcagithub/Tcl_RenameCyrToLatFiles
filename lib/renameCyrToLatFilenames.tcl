################################
# 22/01/2016
# Searches recursivly by dirs files with cyrillic name
# renames these files and renames cyrillic names into all
# htm|xml|js files in these dirs.
#
# In order to start make next preparation:
# tclsh renameCyrToLatFilenames.tcl path_to_dir
#
set auto_path [linsert $auto_path 0 .]

package provide renameCyrToLatFilenames 1.0
package require fileutil
package require properties
# fconfigure stdout -encoding utf-8
# fconfigure stdin -encoding utf-8
encoding system utf-8

namespace eval ::renameCyrToLatFilenames:: {
	namespace export startProcess

	variable _logTextArea
	variable _INFO_FILE "files_mapping.log"
	variable _dicFileNameLatCyr {}
	variable _dicFullPathLatCyr {}
	variable _needRecurs false
	variable _needRename false
	variable _pathDir {}
	variable _exts {} 
	variable _bakPaths {}
	variable _removeBaks false

	# # # # # # # # # # # # # # # #
	# Main exported procedure. 
	#
	#    @params: params - Dict with PATH_DIR
	#							LOG_WIN
	#							CHCK_RECURS
	#							CHCK_RENAME
	#							EXTS
	#    @return: 
	#
	proc startProcess { params } {
		variable _pathDir [dict get $params PATH_DIR]

		if { ![file exists $_pathDir] } {return}
		
		variable _logTextArea	[dict get $params LOG_WIN]
		variable _needRecurs	[dict get $params CHCK_RECURS]
		variable _needRename	[dict get $params CHCK_RENAME]
		variable _exts			[dict get $params EXTS]
		variable _removeBaks	[dict get $params CHCK_REMOVE_BAK]
		variable _progress		[dict get $params PROGRESS]
		
		set travDirs [getTraversedDirs]
		set cyrPaths [getAllCyrPaths $travDirs]
		
		applyMappingAndPersistTo $cyrPaths

		if { [isNeedToRename] } {
			renameFileWithNamePersistent
			updateContentFilesByExts $travDirs
		}
		saveOrRemoveBakFiles

		appendToLogWin "End process."
	}

	# # # # # # # # # # # # # # # #
	# 
	#
	#    @params: 
	#    @return: list of traversed dirs
	#
	proc getTraversedDirs {} {
		variable _needRecurs
		variable _pathDir
		set travDirs {}
		set dirs $_pathDir

	    while {[llength $dirs]} {
	        set dirs [lassign $dirs name]
	        if { $_needRecurs } {
	        	lappend dirs {*}[glob -nocomplain -directory $name -type d *]
	        }
	        lappend travDirs $name
	    }
	    return $travDirs
	}

	proc getAllCyrPaths { dirs } {
		set paths {}
		set excludedPaths {}
		foreach dir $dirs {
			lappend paths {*}[glob -nocomplain -directory $dir -type f *\[А-Яа-я\]*]
			lappend excludedPaths {*}[glob -nocomplain -directory $dir -type f *bak]
		}

		set result [lmap el $paths {
			expr {[lsearch -exact $excludedPaths $el] > -1 ? [continue] : $el}
		}]

		if {[llength $result] == 0 } {
			appendToLogWin "No cyrillic filenames!"
		}
		return $result
	}

	proc not {pattern} {
	    set ret {(?:}     ;# Not capturing bracket
	    foreach char [split $pattern {}] {
	        append ret "\[^$char\]"
	    }
	    append ret ")"
	    return $ret
	}

	proc appendToLogWin { message } {
		variable _logTextArea

		$_logTextArea insert end "$message\n"
		$_logTextArea see end
	}

	proc applyMappingAndPersistTo { cyrillicPaths } {
		variable _dicFileNameLatCyr {}
		variable _dicFullPathLatCyr {}

		set formatPattern "%-40s %s"
		set infos {}
		foreach pathCyr $cyrillicPaths {
			set pathLat [string map $properties::mapping $pathCyr]
			set fileNameLat [file tail $pathLat]
			set fileNameCyr [file tail $pathCyr]

			lappend infos "[format $formatPattern $fileNameCyr $fileNameLat]"

			dict set _dicFileNameLatCyr $fileNameLat $fileNameCyr
			dict set _dicFullPathLatCyr $pathLat $pathCyr
		}
		appendToInfoFile $infos
	}

	proc appendToInfoFile { infos } {
		variable _INFO_FILE

		# if { [llength $infos] == 0 } { return }
		appendTitleTo $infos
		set fileId [open $_INFO_FILE a]
		foreach inf $infos {
			puts $fileId $inf
		}
		flush $fileId
		close $fileId

		appendToLogWin [join $infos "\n"]

	}

	proc appendTitleTo { infos } {
		upvar 1 infos infoList
		set systemTime [clock seconds]
		set infoList [linsert $infoList 0 "-----------------------------------------------------"]
		set infoList [linsert $infoList 1 "--- List of files which 'cyr to lat' were renamed"]
		set infoList [linsert $infoList 2 "--- [clock format $systemTime -format {%a, %d/%m/%Y %R} ]"]
		set infoList [linsert $infoList 3 "-----------------------------------------------------"]
		lappend infoList "\n"
	}

	proc isNeedToRename {} {
		variable _needRename
		variable _dicFullPathLatCyr

		appendToLogWin "Total files with cyrillic names: \
			[dict size $_dicFullPathLatCyr]"
		
		return $_needRename
	}

	proc renameFileWithNamePersistent {} {
		variable _dicFullPathLatCyr
		
		set msg "Rename cyr files..."
		appendToLogWin "Rename cyrillic file names..."

		set total [dict size $_dicFullPathLatCyr]
		dict for {pathLat pathCyr} $_dicFullPathLatCyr {
			moveProgress [incr i] $total $msg
			if {[file extension $pathCyr] eq ".bak"} {
				continue
			}
			backUpCopy $pathCyr
			file rename -force $pathCyr $pathLat
		}
	}

	proc getFilePathsByExtentions { dirs } {
		variable _exts

		set paths {}
		foreach d $dirs {
			foreach e $_exts {
				lappend paths {*}[glob -nocomplain -join -dir $d $e]
			}
		}
		appendToLogWin "Number of ($_exts) files: [llength $paths]"
		return $paths
	}

	proc updateContentFilesByExts { dirs } {
		variable _dicFileNameLatCyr

		set msg "Num updated files..."
		appendToLogWin "Start update content..."
		set paths [getFilePathsByExtentions $dirs]
		set total [llength $paths]
		set tmpPath ""
		foreach pathFile $paths {
			moveProgress [incr i] $total $msg
			dict for {latName cyrName} $_dicFileNameLatCyr {
				fileutil::updateInPlace $pathFile cmdReplacment
			}
		}
	}

	proc cmdReplacment { content } {
		upvar 1 cyrName from
		upvar 1 latName to
		upvar 1 pathFile path
		upvar 1 tmpPath tmp
		if {$tmp != $path && [string match *$from* $content]} {
			set tmp $path
			backUpCopy ${path} "_"
		}
		# string map [dict create $from $to] $content
		string map [list $from $to] $content
	}

	proc backUpCopy {path {suffix ""} } {
		variable _bakPaths

		set bak "${path}${suffix}.bak"
		appendToLogWin "Creating $bak"
		file copy -force $path "$bak"
		lappend _bakPaths "$bak"
	}

	proc saveOrRemoveBakFiles {} {
		variable _removeBaks
		variable _bakPaths
		
		if {$_removeBaks} {
			removeBakFiles
		} else {
			saveBaksToFile
		}

		set _bakPaths {}
	}

	proc saveBaksToFile {} {
		variable _bakPaths

		if {[llength $_bakPaths] == 0} {
			return
		}
		set msg "Creating bak files..."
		appendToLogWin "Creating $properties::bakFilesLog"
		set total [llength $_bakPaths]
		set logId [open $properties::bakFilesLog "a"]
		foreach bakFile $_bakPaths {
			moveProgress [incr i] $total $msg
			puts $logId $bakFile
		}
		close $logId
	}

	proc removeBakFiles {} {
		variable _bakPaths

		set bakFiles {}
		if {[file exists $properties::bakFilesLog]} {
			set fileId [open $properties::bakFilesLog "r"]
			set bakFiles [split [read $fileId] "\n"]
			close $fileId
			file delete $properties::bakFilesLog
		}	

		lappend bakFiles {*}$_bakPaths
		set msg "Deleting bak files..."
		appendToLogWin "Deleting $properties::bakFilesLog"
		set total [llength $bakFiles]
		foreach bakFile $bakFiles {
			moveProgress [incr i] $total $msg
			file delete $bakFile
		}
	}

	proc moveProgress {i total {msg $properties::labelProgress} } {
		variable _progress
		if {$total == 0} {return}
		set value [expr {$properties::progressLength * $i/$total}]
		$_progress configure -sliderlength $value \
			-label "$msg $i/$total"

		update idletasks
        # after 10
	}

	proc stubLog {var1 var2 {message "see end"}} {
		puts "Test: \n$message\n"
	}

	proc stubProgress {var1 var2 var3 var4 var5} {
		puts "Test: Progress $var1 $var2 $var3 $var4 $var5\n"
	}

	proc test {} {
		startProcess [dict create \
			PATH_DIR /home/gca/Projects/Tcl_Tk/Help \
			LOG_WIN stubLog \
			CHCK_RECURS false \
			CHCK_RENAME true \
			CHCK_REMOVE_BAK false \
			PROGRESS stubProgress \
			EXTS "*.html *.xml *.js"]

	}

}

# # # # # # # # # # # # # # # #
# Test procedure
#
#    @params: 
#    @return: 
#
::renameCyrToLatFilenames::test

