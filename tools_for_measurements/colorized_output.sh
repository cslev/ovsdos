#!/bin/bash

#===================   COLORIZING  OUTPUT =================
declare -A colors
colors=(
	[none]='\033[0m'
	[bold]='\033[01m'
	[disable]='\033[02m'
	[underline]='\033[04m'
	[reverse]='\033[07m'
	[strikethrough]='\033[09m'
	[invisible]='\033[08m'
	[black]='\033[30m'
	[red]='\033[31m'
	[green]='\033[32m'
	[orange]='\033[33m'
	[blue]='\033[34m'
	[purple]='\033[35m'
	[cyan]='\033[36m'
	[lightgrey]='\033[37m'
	[darkgrey]='\033[90m'
	[lightred]='\033[91m'
	[lightgreen]='\033[92m'
	[yellow]='\033[93m'
	[lightblue]='\033[94m'
	[pink]='\033[95m'
	[lightcyan]='\033[96m'

)
num_colors=${#colors[@]}
# -----------------------------------------------------------

# ==================== USE THIS FUNCTION TO PRINT TO STDOUT =============
# $1: color
# $2: text to print out
# $3: no_newline - if nothing is provided newline will be printed at the end
#				 - anything provided, NO newline is indicated
function c_print () {
	color=$1
	text=$2
	no_newline=$3
	#if color exists/defined in the array
	if [[ ${colors[$color]} ]]
	then
		text_to_print="${colors[$color]}${text}${colors[none]}" #colorized output
	else
		text_to_print="${text}" #normal output
	fi

	if [ -z "$no_newline" ]
	then
		echo -e $text_to_print # newline at the end
	else
		echo -en $text_to_print # NO newline at the end
	fi

}
# -----------------------------------------------------------

