#/bin/bash

INTERVAL=1
FILE=$1
URL=$2
INPUTDIR=./input/
OUTPUTDIR=./output/
CONFIG=$HOME/.config/Atauto/
A=$(printf "%x" $(printf "%d" \'A))
a=$(printf "%x" $(printf "%d" \'a))

#-h text
function HELPCMD(){
	echo "USAGE"
	echo "  Atauto.sh <source file> <url>"
	echo "OPTHIONS"
	echo "   -h: show help"
	echo "PURPOSE"
	echo "   This command can compile automatically that you input good source file."
	echo "   This has compile command above default."
	echo "	 make"
	echo "	 gcc -o (basename without source file) (source file)"
	echo "	 java (source file)"
	echo "	 platex (source file) ; platex (source file) ; dvipdfmx (basename source file).dvi"
	echo "	 rustc (source file)"
	echo "   If you want to compile other language, you have to write in ~/.config/Atauto/."
}

#read source file and check about extend and existing
function READFILE(){
	if [ -z "$FILE" ] ; then
		echo "Please input your program file"
		read FILE
	fi
	if [[ -z $URL ]] ; then 
		echo "Please input url"
		read URL
	fi
	EXT=${FILE##*.}
	FILENAME=`basename $FILE`
	DIRNAME=`dirname $FILE`
	if [ "$DIRNAME" == "." ] ; then
		FULL=`pwd`/${FILENAME}
		EXEFILE=`pwd`/${FILENAME%.*}
	else
		FULL=`pwd`/${DIRNAME}/${FILENAME}
		EXEFILE=`pwd`/${DIRNAME}/${FILENAME%.*}
	fi
	check="s"
	if [ ! -e "$FULL" ] ; then
		echo "This file doesn't exist."
		ans="0"
		echo "\"$FILE\":Do you edit new file?(y/n)"
		read ans
		if [ "$ans" == "n" ] ; then
			exit 1
		fi
	check="0"
	fi
	SCRAPING $URL
}

function SCRAPING(){
	if [[ $(echo $URL | grep "tasks") = "" ]] ; then
		echo "input tasks url."
		exit 7
	fi
	rm -rf $INPUTDIR/* $OUTPUTDIR/*
	if [[ $(echo $URL | grep "atcoder") != "" ]] ; then
		curl -o baseurl.txt $URL
		URLTOP=https://atcoder.jp

		for ((i=1;i<=$(cat baseurl.txt | grep "<td class=\"text-center" | wc -l);i++)) ; do
			STR=$(cat baseurl.txt | grep "<td class=\"text-center" | awk -v n=$i 'NR==n')
			STRN=$(echo ${STR%\'*})
			curl -o curl_get_problem.txt $URLTOP${STRN#*\'}
			mkdir $INPUTDIR$(printf "\x$(($A + $i - 1))") $OUTPUTDIR$(printf "\x$(($A + $i - 1))")
			$HOME/.local/bin/get_testcase curl_get_problem.txt $i
		done
	fi
	rm baseurl.txt curl_get_problem.txt
}

#conf->command,execution. maybe change
function INDIRECTEXPANTION(){
	RETTMP=$(cat $CONFIG/$1 | grep $2)
	RETTMPS=$(echo ${RETTMP#*=})
	ARG3=$3
	TMP3='$ARG3'
	echo $(eval echo ${RETTMPS//"filename"/$TMP3})
}

function EXE (){
	for i in $(ls -1 $CONFIG) ; do
		if [[ $EXT = ${i%.*} ]] ; then
			TMP=`INDIRECTEXPANTION $i "command" ${FILENAME%.*}`
			COMMAND=$(echo ${TMP})
			TMP=`INDIRECTEXPANTION $i "command" ${FILENAME%.*}`
			COMMANDSTR=$(echo ${TMP})
			TMP=`INDIRECTEXPANTION $i "execution" ${FILENAME%.*}`
			EXE=$(echo ${TMP})
		fi
	done
	if [ -e "Makefile" ] ; then
		COMMAND="make"
		COMMANDSTR="make"
	fi
	echo "$COMMANDSTR"
	echo "$EXE"
}

#editor
function STARTEDITOR(){
	if [ "$EDITOR" == "emacs" ] ; then
		touch $FULL
			pid=`ps -ef | grep "$EDITOR $FILE" | grep -v grep | awk '{print $2}'`
			if [ -z "$pid" ] ; then
			fprocess=`ps --no-heading -C $EDITOR -o pid`
			$EDITOR $FULL &
			bprocess=`ps --no-heading -C $EDITOR -o pid`
			pid=$(join -v 1 <(echo "$bprocess") <(echo "$fprocess"))
   		fi
		before=`ls --full-time $FULL | awk '{print $6" - "$7}'`
	fi
	if [ "$EDITOR" == "vim" ] ; then
		touch $FULL
			pid=`ps -ef | grep "$EDITOR $FILE" | grep -v grep | awk '{print $2}'`
			if [ -z "$pid" ] ; then
			fprocess=`ps --no-heading -C xterm -o pid`
			xterm -bg black -fg white -e vim $FULL &
			bprocess=`ps --no-heading -C xterm -o pid`
			pid=$(join -v 1 <(echo "$bprocess") <(echo "$fprocess"))
   		fi
		before=`ls --full-time $FULL | awk '{print $6" - "$7}'`
	fi
}

#loop
function EXECHECK(){
	echo "Which is the problem? if you don't input,don't running.[a-$(printf "\x$(($a + $(ls -1 ./input/ | wc -l) -1))")]"
	read abcd
	if [[ $abcd = "" ]] ; then 
		return
	fi
	INPUTFILE=${INPUTDIR}$(printf "\x$(($A + $(printf "%x" $(printf "%d" \'$abcd)) - $a))")
	OUTPUTFILE=${OUTPUTDIR}$(printf "\x$(($A + $(printf "%x" $(printf "%d" \'$abcd)) - $a))")

	for ((i=1; i <=$(ls -l $INPUTFILE | grep input | wc -l); i++)) ; do
		$EXE < $INPUTFILE/input$i.txt > checktemplate.txt 
		if [[ $? != 0 ]] ; then
			echo "RE"
		fi
		diff checktemplate.txt $OUTPUTFILE/output$i.txt
		if [[ $? != 0 ]] ; then 
			echo "WA"
			echo "your sourses output."
			cat checktemplate.txt
			echo "correct answer"
			cat $OUTPUTFILE/output$i.txt
		else
			echo "AC"
		fi
	done	
	rm checktemplate.txt
	unset INPUTFILE
	unset OUTPUTFILE
}

function LOOPSUB(){
	now=`ls --full-time $FULL | awk '{print $6" - "$7}'`
	if [ "$now" != "$before" ] ; then
	echo "compile"
	$COMMAND
	comp=$?
	echo "$comp"
	if [ "$comp" == "0" ] ; then
		EXECHECK
	fi
	before=$now
	fi
}

function LOOPCMP(){
	while [ -n "$pid" ] 
	do
	if [ "$check" != "s" ] ; then
		echo "If you input \"s\", start compile"
		read check
	fi
	LOOPSUB
	sleep $INTERVAL
	pid=`ps -p $pid --no-heading | grep -v grep | awk '{print $1}'`
	done
}

#last

function LAST(){
	echo "last"
	if  [ ! -e "$EXEFILE" ] ; then
		if [ "$check" != "s" ] ; then
			echo "rm $FILE"
			rm $FILE
			echo "finish"
			return
		fi
	fi
	EXECHECK
	echo "finish."
}


#main
if [ "$1" == "-h" ] ; then
	HELPCMD
	exit 0
fi
READFILE
EXE
STARTEDITOR #before setting
LOOPCMP #diff now before
LAST
exit 0
