#!/bin/bash

#SBATCH --job-name=submit-strong-omp.sh
#SBATCH -D .
#SBATCH --output=submit-strong-omp.sh.o%j
#SBATCH --error=submit-strong-omp.sh.e%j

SEQ=mandel-seq
PROG=mandel-omp
size=10000
np_NMIN=1
np_NMAX=12
N=3

# Make sure that all binaries exist
make $SEQ
make $PROG

out=/tmp/out.$$	    # Temporal file where you save the execution results
aux=/tmp/aux.$$     # archivo auxiliar

outputpath=./elapsed.txt
outputpath2=./speedup.txt
rm -rf $outputpath 2> /dev/null
rm -rf $outputpath2 2> /dev/null

echo Executing $SEQ sequentially
elapsed=0  # Acumulacion del elapsed time de las N ejecuciones del programa
i=0        # Variable contador de repeticiones
while (test $i -lt $N)
	do
		echo -n Run $i...
		/usr/bin/time --format=%e ./$SEQ -h -i $size > $out 2>$aux

		time=`cat $aux|tail -n 1`
		echo Elapsed time = `cat $aux`

		elapsed=`echo $elapsed + $time|bc`

		rm -f $out
		rm -f $aux
		i=`expr $i + 1`
	done
echo -n ELAPSED TIME AVERAGE OF $N EXECUTIONS =
sequential=`echo $elapsed/$N|bc -l`
echo $sequential
echo

echo "$PROG $size $np_NMIN $np_NMAX $N"

i=0
echo "Starting OpenMP executions..."

PARS=$np_NMIN
while (test $PARS -le $np_NMAX)
do
	echo Executing $PROG with $PARS threads
	elapsed=0  # Acumulacion del elapsed time de las N ejecuciones del programa

	while (test $i -lt $N)
		do
			echo -n Run $i...
                        export OMP_NUM_THREADS=$PARS
			/usr/bin/time --format=%e ./$PROG -h -i $size > $out 2>$aux

			time=`cat $aux|tail -n 1`
			echo Elapsed time = `cat $aux`

			elapsed=`echo $elapsed + $time|bc`

			rm -f $out
			rm -f $aux
			i=`expr $i + 1`
		done

	echo -n ELAPSED TIME AVERAGE OF $N EXECUTIONS =

    	average=`echo $elapsed/$N|bc -l`
    	result=`echo $sequential/$average|bc -l`
    	echo $average
	echo
	i=0

    	#output PARS i average en fichero elapsed time
	echo -n $PARS >> $outputpath
	echo -n "   " >> $outputpath
    	echo $average >> $outputpath

    	#output PARS i result en fichero speedup
	echo -n $PARS >> $outputpath2
	echo -n "   " >> $outputpath2
    	echo $result >> $outputpath2

    	#incrementa el parametre
	PARS=`expr $PARS + 1`
done

echo "Resultat de l'experiment (tambe es troben a " $outputpath " i " $outputpath2 " )"
echo "#threads	Elapsed average"
cat $outputpath
echo
echo "#threads	Speedup"
cat $outputpath2
echo

jgraph -P strong-omp.jgr >  $PROG-$size-strong-omp.ps
usuario=`whoami`
fecha=`date`
sed -i -e "s/UUU/$usuario/g" $PROG-$size-strong-omp.ps
sed -i -e "s/FFF/$fecha/g" $PROG-$size-strong-omp.ps

