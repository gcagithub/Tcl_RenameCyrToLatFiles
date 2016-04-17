# Properties file

package provide properties 1.0

namespace eval ::properties:: {

	variable labelTitleWM "Rename cyrillic files"
	variable labelPathToDir "- path directory"
	variable labelFileExts "- rename cyrillic names within these files"
	variable labelRecurs "- looking for dirs recursivly"
	variable labelNeedRename "- rename file names"
	variable labelNeedRemoveBaks "- remove bak files"
	variable labelStartProcess "Run"
	variable labelOpenDir "..."
	variable messageWrongPath "Path to dir is not exist!"
	variable fldExts "*.htm *.xml *.js"
	variable labelProgress "Progress:"
	variable progressLength 200

	variable bakFilesLog "bak_files.log"
	variable mapping {
			а a б b в v г g д d е e ё yo ж zh з z и i й j к k л l м m н n о o п p р r с s т t у u ф f х kh ц ts ч ch ш sh щ sch ъ "" ы y ь "" э ae ю yu я ja \
			А A Б B В V Г G Д D Е E Ё YO Ж Zh З Z И I Й J К K Л L М M Н N О O П P Р R С S Т T У U Ф F Х Kh Ц ts Ч CH Ш SH Щ SCH Ъ "" Ы Y Ь "" Э Ae Ю Yu Я JA
	}


}