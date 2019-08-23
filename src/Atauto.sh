#/bin/bash

INTERVAL=1
FILE=$1
TEST=test.txt
URL=$2
INPUTDIR=./input/
OUTPUTDIR=./output/
CONFIG=$HOME/.config/Atauto/
A=$(printf "%x" $(printf "%d" \'A))
a=$(printf "%x" $(printf "%d" \'a))
dataTaskScreenName=()
SUBMITURL=()

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
	rm -rf $INPUTDIR/* $OUTPUTDIR/*
	SCRAPING $URL
}

function SCRAPING(){
	u=$(cat ${CONFIG}.user.conf | awk 'NR==1')
	p=$(cat ${CONFIG}.user.conf | awk 'NR==2')
	CSRFF=$(curl --cookie-jar ${CONFIG}.cookie https://atcoder.jp/login | grep csrf_token)
	CSRFS=${CSRFF##*value=\"}
	CSRFT=${CSRFS%\"*}
	CSRFY=${CSRFT//\&\#43/+}
	curl -sS -X POST https://atcoder.jp/login -F "username=${u}" -F "password=${p}" -F "csrf_token=${CSRFY//\;/}" --cookie ${CONFIG}.cookie --cookie-jar ${CONFIG}.cookie.log -f
	if [[ $? != 0 ]] ; then 
		echo "curl error"
		exit 22
	fi	

	#for atcoder.jp
	if [[ $(echo $URL | grep "atcoder") != "" ]] ; then
		URLTOP=https://atcoder.jp
		if [[ $(echo $URL | grep "tasks") = "" ]] ; then
			echo "input tasks url."
			exit 7
		fi
		curl -s --cookie ${CONFIG}.cookie.log -o baseurl.txt ${URL}
		max=$(cat baseurl.txt | grep "<td class=\"text-center" | wc -l)
		echo "max=$max"
		AZCount=1
		for i in {A..Z} ; do
			if [[ ${AZCount} -gt $max ]] ; then
				break;
			fi
			STR=$(cat baseurl.txt | grep "<td class=\"text-center" | awk -v n=${AZCount} 'NR==n')
			STRN=$(echo ${STR%\'*})
			echo ${max} ${STRN#*\'}
			curl -s --cookie ${CONFIG}.cookie.log -o curl_get_problem.txt $URLTOP${STRN#*\'}
			mkdir $INPUTDIR${i} $OUTPUTDIR${i}
			$HOME/.local/bin/get_testcase curl_get_problem.txt ${AZCount}
			GTASK=${STRN#*/}
			dataTaskScreenName+=(${GTASK#*tasks/})
			SUBMITURL+=(${URL%/*}/submit)
			AZCount=$((${AZCount} + 1))
		done
	# for vatual
	elif [[ $(echo $URL | grep "not-522") != "" ]] ; then 
		URLTOP=https://atcoder.jp/contests
		if [[ $(echo $URL | grep "contest") = "" ]] ; then
			echo "input tasks url."
			exit 7
		fi
		curl -s -o baseurl.txt $URL
		max=$(cat baseurl.txt | grep $URLTOP | wc -l)
		AZCount=1
		for i in {A..Z} ; do
			if [[ ${AZCount} -gt $max ]] ; then
				break;
			fi
			
			STR=$(cat baseurl.txt | grep $URLTOP | awk -v n=${AZCount} 'NR==n')
			STRN=$(echo ${STR%\" target*})
			curl -s -o curl_get_problem.txt ${STRN#*\"}
			mkdir ${INPUTDIR}${i} ${OUTPUTDIR}${i}
			$HOME/.local/bin/get_testcase curl_get_problem.txt ${AZCount}
			GTASK=${STRN#*/}
			dataTaskScreenName+=(${GTASK#*tasks/})
			SUBMITURL+=(https:/${GTASK%tasks/*}submit)
			AZCount=$(($AZCount + 1))
		done
	fi
	rm baseurl.txt curl_get_problem.txt
}

#conf->command,execution. maybe change
function INDIRECTEXPANTION(){
	RETTMP=$(cat $CONFIG$1 | grep $2)
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
			TMP=$(cat ${CONFIG}${i} | grep "langid")
			LangID=$(echo ${TMP#*=})
		fi
	done
	if [ -e "Makefile" ] ; then
		COMMAND="make"
		COMMANDSTR="make"
	fi
}

#editor
function STARTEDITOR(){
	touch $FULL
	touch $TEST
	if [ "$EDITOR" == "emacs" ] ; then
		pid=`ps -ef | grep "$EDITOR $FILE" | grep -v grep | awk '{print $2}'`
		if [ -z "$pid" ] ; then
#			fprocess=`ps --no-heading -C $EDITOR -o pid`
#			$EDITOR $FULL &
#			bprocess=`ps --no-heading -C $EDITOR -o pid`
#			pid=$(join -v 1 <(echo "$bprocess") <(echo "$fprocess"))
#			sprocess=`ps --no-heading -C $EDITOR -o pid`
#			$EDITOR $TEST &
#			kprocess=`ps --no-heading -C $EDITOR -o pid`
#			testpid=$(join -v 1 <(echo "$kprocess") <(echo "$sprocess"))
			$EDITOR $FULL &
			pid=$!
			$EDITOR $TEST &
			testpid=$!
   		fi
		before=`ls --full-time $FULL | awk '{print $6" - "$7}'`
		testbefore=`ls --full-time $TEST | awk '{print $6" - "$7}'`
		
	fi
	if [ "$EDITOR" == "vim" ] ; then
		pid=`ps -ef | grep "$EDITOR $FILE" | grep -v grep | awk '{print $2}'`
		if [ -z "$pid" ] ; then
#			fprocess=`ps --no-heading -C xterm -o pid`
#			xterm -bg black -fg white -e vim $FULL &
#			bprocess=`ps --no-heading -C xterm -o pid`
#			pid=$(join -v 1 <(echo "$bprocess") <(echo "$fprocess"))
#			sprocess=`ps --no-heading -C xterm -o pid`
#			xterm -bg black -fg white -e vim $TEST &
#			kprocess=`ps --no-heading -C xterm -o pid`
#			testpid=$(join -v 1 <(echo "$kprocess") <(echo "$sprocess"))
			xterm -e vim $FULL &
			pid=$!
			xterm -e vim $TEST &
			testpid=$!
   		fi
		before=`ls --full-time $FULL | awk '{print $6" - "$7}'`
		testbefore=`ls --full-time $TEST | awk '{print $6" - "$7}'`
	fi
}

function TLECHECK(){
	timeout --preserve-status 2 ${EXE} < ${1} > checktemplate.txt
	# sh -c "${EXE} < ${1} > checktemplate.txt" &
	# shid=$!
	# sh -c "sleep 2 ; ps --ppid ${shid} --no-headers -o pid | xargs kill -9 ; kill -9 ${shid}" &
	# sleepid=$!
	# wait ${shid}
	if [[ $? != 0 ]] ; then 
		echo TLE
	else
	 	kill -9 ${sleepid} &> /dev/null
	fi
}

#loop
function EXECHECK(){
	echo "Which is the problem? if you don't input,don't running.[a-$(printf "\x$(($a + $(ls -1 ./input/ | wc -l) -1))"),test]"
	read abcd
	if [[ $abcd = "" ]] ; then 
		return
	elif [[ $abcd = "test" ]] ; then
		TLECHECK $TEST
		cat checktemplate.txt
	else	
		INPUTFILE=${INPUTDIR}$(printf "\x$(($A + $(printf "%x" $(printf "%d" \'$abcd)) - $a))")
		OUTPUTFILE=${OUTPUTDIR}$(printf "\x$(($A + $(printf "%x" $(printf "%d" \'$abcd)) - $a))")
		for ((i=1,j=1; i <=$(ls -l $INPUTFILE | grep input | wc -l); i++)) ; do
			TLECHECK $INPUTFILE/input$i.txt 
			diff checktemplate.txt $OUTPUTFILE/output$i.txt
			if [[ $? != 0 ]] ; then 
				echo "WA"
			else
				echo "AC"
				j=$((++j))
			fi
		done	
	fi
	rm checktemplate.txt
	if [[ $i = $j || $abcd = "test" ]] ; then
		echo "All testcase is ok. submit?(y/N)"
		read submitcheck
		if [[ $submitcheck = "y" ]] ; then
			echo $(curl -sS -X POST ${SUBMITURL[$(printf "%x" $(printf "%d" \'$abcd)) - $a]} \
				-F "data.TaskScreenName=${dataTaskScreenName[$(printf "%x" $(printf "%d" \'$abcd)) - $a]}" \
				-F "data.LanguageId=${LangID}" \
				-F "csrf_token=${CSRFY//\;/}" \
				-F "sourceCode=$(cat $FILE)" \
				--cookie ${CONFIG}.cookie.log -f)
		fi
	fi
	unset INPUTFILE
	unset OUTPUTFILE
}

function LOOPSUB(){
	now=`ls --full-time $FULL | awk '{print $6" - "$7}'`
	testnow=`ls --full-time $TEST | awk '{print $6" - "$7}'`
	if [ "$now" != "$before" -o "$testnow" != "$testbefore" ] ; then
		echo "compile"
		$COMMAND
		comp=$?
		if [ "$comp" == "0" ] ; then
			EXECHECK
		fi
		before=$now
		testbefore=$testnow
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
	testpid=`ps -p $testpid --no-heading | grep -v grep | awk '{print $1}'`
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
	kill -15 $testpid
	# rm ${CONFIG}.cookie ${CONFIG}.cookie.log &> /dev/null
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
