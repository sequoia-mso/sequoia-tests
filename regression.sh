#!/bin/bash

ulimit -m 4194304
ulimit -c unlimited

SEQUOIA=../sequoia-core

function die() {
	# Add random number to output, such that w.h.p. we have
	# a different output on each call and the compare() stops
	# with error, even if the original die comes from a subshell
	echo "-$RANDOM- Error: $*"
	exit 1
}

function run()  {
	TDC=
	if [ -f "$4" ]; then
		TDC="-t $4"
	fi
	nice $SEQUOIA/src/sequoia -T4 -f $1 -e $2 -g $3 $TDC
	if [ $? -gt 0 ]; then die "Error on program call for $1 $2 $3 $TDC"; fi
}

function compare() {
	echo Checking $1 $2 $3
	FORMULA=$2
	if [ $FORMULA = "3col.mso" ]; then
		FORMULA=3col-free2.mso # hack to avoid duplicate result files
	fi
	RESFILE=results/$1_$FORMULA
	if [ ! -f $RESFILE ]; then
		die No precomputed result file found. $RESFILE
	fi
	RES="`tail -n 1 $RESFILE`"
	[ "$3" = "$RES" ] || die "found different results: '$3' vs. saved '$RES' on $G with $FORMULA"
}

function loop_rand() {
	FORMULA=$1
	EVAL=$2
	MAX=$3

	FILEA=`mktemp`
	for G in graphs/*; do
		echo "******************************************************************"
		echo -n $FORMULA $G ": "
		TW=`$SEQUOIA/tools/compute_tw_bound $G`
		if [ $TW -gt $MAX ]; then
			echo "treewidth too large, skip."
			continue
		else 
			echo "treewidth $TW"
		fi
		run $SEQUOIA/examples/$FORMULA $EVAL $G | tee $FILEA
		RESA="`tail -n 1 $FILEA`"
		compare `basename $G` $FORMULA "$RESA"
	done
	rm $FILEA
}

function loop_grid() {
	FORMULA=$1
	EVAL=$2
	MAX=$3

	FILEA=`mktemp`
	FILEB=`mktemp`

	for k in $(seq $MAX); do
		if [ $k -gt 8 ]; then # grids only go up to 8 for now
			continue
		fi
		for G in grids/grid_${k}_*; do
			echo "******************************************************************"
			echo $FORMULA $G
			run $SEQUOIA/examples/$FORMULA $EVAL $G tdcs/$(basename $G).tdc | tee $FILEA
			run $SEQUOIA/examples/$FORMULA $EVAL $G | tee $FILEB
			RESA=`tail -n 1 $FILEA`
			RESB=`tail -n 1 $FILEB`
			[ "$RESA" = "$RESB" ] || die "found different results: $RESA vs. $RESB on $G with $FORMULA"
			compare `basename $G` $FORMULA "$RESA"
		done;
	done

	rm $FILEA
	rm $FILEB
}

function loop() {
	loop_rand $1 $2 $3
	loop_grid $1 $2 $3
}

[ -x $SEQUOIA/src/sequoia ] || die "sequoia executable missing, run make first."

loop vertex-cover.mso MinCard 7
loop dominating-set.mso MinCard 5
loop independent-set.mso MaxCard 7
loop clique.mso MaxCard 9
loop d2-dominating-set.mso MinCard 3
loop 3col-free2.mso Bool 4
loop 3col.mso Bool 4 # needed for set moves
loop connected.mso Bool 20
loop connected-domset.mso MinCard 4
loop bipartite.mso Bool 15
