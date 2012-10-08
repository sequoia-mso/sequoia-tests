#!/bin/sh

echo "Error: Please read the comment in the shell script."
exit 1

# This file originally created the various
# graph files found in the subfolders.
# In the meantime, however, the gen_grid_tdc.cpp
# file changed its logic; hence the created
# graphs cannot be reproduced the same way as before,
# and this file is here mostly for historical reasons.

if [ ! -x /usr/bin/seq ]; then
	echo "Error:  /usr/bin/seq not found or not executable."
	exit 1
fi

SEED=1
M=8
N=125
R=10

for W in $(/usr/bin/seq $M); do 
	for P in `/usr/bin/seq 1.0 -0.05 0.05`; do 
		H=$HEIGHT
		if [ $P = 1.00 ]; then
			OFT=1
		else
			OFT=$(/usr/bin/seq $R)
		fi
		for n in $OFT; do
			F=grid_${W}_${N}_${P}_${SEED}
			echo $F
			../project/src/gen_grid_tdc grids/$F tdcs/$F.tdc $W $N $P $SEED
			SEED=$((SEED+1))
		done
	done
done

NRAND=20
SEED=1
for i in `/usr/bin/seq $NRAND`; do
	for P in `/usr/bin/seq 0.02 -0.0005 0.0`; do 
		echo $P $SEED
		../project/src/gen_rand_graph graphs/rand_${N}_${P}_${SEED} $N $P $SEED
		SEED=$((SEED+1))
	done
done
