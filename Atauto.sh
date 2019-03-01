#!/bin/bash

INTERVAL=1
FILE=$1

#-h text
function HELPCMD(){
    echo "USAGE"
    echo "  .auto_compiler <source file>"
    echo " or"
    echo "  .auto_compiler"
    echo "  (if you forget input source file.)"
    echo "OPTHIONS"
    echo "   -h: show help"
    echo "PURPOSE"
    echo "   This command can compile automatically that you input good source file."
    echo "   This has compile command above default."
    echo "     make"
    echo "     gcc -o (basename without source file) (source file)"
    echo "     java (source file)"
    echo "     platex (source file) ; platex (source file) ; dvipdfmx (basename source file).dvi"
    echo "     rustc (source file)"
    echo "   If you want to compile other language, you have to write in this scripts file."
}

#read source file and check about extend and existing
function READFILE(){
    if [ -z "$FILE" ] ; then
	echo "Please input your program file"
	read FILE
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
}

#This line is compile command and execution command.
function GCC(){
    COMMAND="gcc -o ${FILENAME%.*} $FILE" 
    EXE="./${FILENAME%.*}"
    COMMANDSTR="gcc -o ${FILENAME%.*} $FILE"
    if [ "$check" == "0" ] ; then
	echo "#include<stdio.h>
int main(void){
  return 0;
}" >>$FILE
    fi
}

function JAVAC(){
    COMMAND="javac $FILENAME" 
    EXE="java ${FILENAME%.*}"
    COMMANDSTR="javac $FILENAME"
    if [ "$check" == "0" ] ; then
	echo "public class ${FILENAME%.*}{
	public static void main(String[] args){
	}
}" >>$FILE
    fi
    EXEFILE=${EXE}.class
}

#TEX compile
function TEX(){
    COMMAND=TEXCMP
    EXE=STARTEVINCE
    if [ "$check" == "0" ] ; then
	cp $(dirname `find $HOME -name .auto_compiler -type f 2> /dev/null`)/.tmp_auto/template.txt $FILE 
    fi
    COMMANDSTR="platex $FILENAME
    platex $FILENAME
    dvipdfmx ${FILENAME%.*}.dvi"
}

function TEXCMP(){
    platex $FILENAME
    platex $FILENAME
    dvipdfmx ${FILENAME%.*}.dvi
}

#TEX check(using evince)
function STARTEVINCE(){
    evincepid=`ps -ef | grep "mupdf ${FILENAME%.*}.pdf" | grep -v grep | awk '{print $2}'` ;
    if [ -z "$evincepid" ] ; then
	fevinceprocess=`ps --no-heading -C mupdf -o pid`
	mupdf ${FILENAME%.*}.pdf &
	bevinceprocess=`ps --no-heading -C mupdf -o pid`
	evincepid=$(join -v 1 <(echo "$bevinceprocess") <(echo "$fevinceprocess"))
    fi
}

function FINEVINCE(){
    if [ -n "$evincepid" ] ; then
	kill -9 $evincepid
    fi
}

#rust
function RASTC(){
    COMMAND="rastc $FILENAME"
    COMMANDSTR="rastc $FILENAME"
    EXE="./${FILENAME%.*}"
}

#haskell
function GHC(){
    COMMAND="stack ghc $FILENAME"
    COMMANDSTR="stack ghc $FILENAME"
    EXE="./${FILENAME%.*}"
}
#you have to input compiler to need for you.

function EXE (){
    case "$EXT" in
	"c"    ) GCC;;
	"java" ) JAVAC;;
	"tex"  ) TEX;;
	"rs"   ) RASTC;;
	"hs"   ) GHC;;
    esac  
    if [ -e "Makefile" ] ; then
	COMMAND="make"
	COMMANDSTR="make"
    fi
    echo "$COMMANDSTR"
}

# check command and read to input argument and redirection fileecho "start."
function CHECKCMD(){
	TEXT=test.txt
	if [ -n "$TEXT" ] ; then
	    TEXTNAME=`basename $TEXT`
	    DIRTEXT=`dirname $TEXT`
	    FULLTEXT=`pwd`/${DIRTEXT}/${TEXTNAME}
	fi
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
		$EDITOR $FULLTEXT &
                bbprocess=`ps --no-heading -C $EDITOR -o pid`
                tpid=$(join -v 1 <(echo "$bbprocess") <(echo "$bprocess"))
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
		xterm -bg black -fg white -e vim $FULLTEXT &
		bbprocess=`ps --no-heading -C xterm -o pid`
		tpid=$(join -v 1 <(echo "$bbprocess") <(echo "$bprocess"))
	fi
}

#loop
function EXECHECK(){
    if [ "$answer" != "n" ] ; then
	if [ -n "$FULLTEXT" ] ; then
	    if [ -n "$ARGUMENT" ] ; then
		echo "execution"
		$EXE $ARGUMENT < $FULLTEXT
	    else
		echo "execution"
		$EXE < $FULLTEXT
	    fi
	else
	    if [ -n "$ARGUMENT" ] ; then
		echo "execution"
		$EXE $ARGUMENT
	    else
		echo "execution"
		$EXE
	    fi
	fi
    fi
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
function FINEXE(){
    FINEVINCE
}

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
    kill `ps ho pid --ppid=$tpid`
    if [ "$answer" == "n" ] ; then
	CHECKCMD
    fi
    EXECHECK
    FINEXE
    echo "finish."
}


#main
if [ "$1" == "-h" ] ; then
    HELPCMD
    exit 0
fi
READFILE
EXE
CHECKCMD
STARTEDITOR #before setting
LOOPCMP #diff now before
LAST
exit 0
