#!/bin/bash
# author: Lennart Ochel

TEST_CLASS="ScalableTestSuite.Thermal.Advection.ScaledExperiments.SteamPipe"
echo "Generating scaling report for $TEST_CLASS"

mkdir -p summary/$TEST_CLASS
HTML_FILE=summary/$TEST_CLASS/index.html

echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body>" > $HTML_FILE
echo "<h1>OpenModelica - Scaling Overview</h1>" >> $HTML_FILE
echo "model class: $TEST_CLASS" >> $HTML_FILE

echo "<h2>Summary</h2>" >> $HTML_FILE
echo "<img src=\"plot-0.png\">" >> $HTML_FILE

FIRST_FILE=$(ls dumps/$TEST_CLASS"_N_2560/"$TEST_CLASS"_N_"*.txt | sort -n | tail -n1)
TESTS=$(ls dumps/$TEST_CLASS* -d | grep -o -P '(?<=_N_).*' | sort -n)
ID=0

grep -o -P '(?<=Notification: Performance of ).*(?=: time)' $FIRST_FILE | while read PHASE
do
  ID=$((ID+1))

  echo "<h2>$PHASE</h2>" >> $HTML_FILE
  echo "<img src=\"plot-$ID.png\">" >> $HTML_FILE

  echo "<table border=\"1\">" >> $HTML_FILE
  echo "<td>date</td><td>OpenModelica</td><td>OMCompiler</td><td>N</td><td>time</td><td>accumulated time</td><td>allocations</td><td>accumulated allocations</td><td>free</td><td>accumulated free</td>" >> $HTML_FILE
  echo -n > temp.dat

  for TEST in $TESTS
  do
    FILE=$(ls dumps/$TEST_CLASS"_N_"$TEST/$TEST_CLASS"_N_"$TEST-*.txt | sort -n | tail -n1)
    TIMESTAMP=$(grep -o -m1 -P '(?<=OpenModelica-timestamp: ).*' $FILE)
    echo -n "<tr><td>$(date -d @$TIMESTAMP +'%m/%d-%y %H:%M')</td><td><a href=\"https://github.com/OpenModelica/OpenModelica/commit/$(grep OpenModelica- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep -o -m1 -P '(?<=OpenModelica-).*' $FILE)</a></td><td><a href=\"https://github.com/OpenModelica/OMCompiler/commit/$(grep OMCompiler- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep -o -m1 -P '(?<=OMCompiler-).*' $FILE)</a></td><td>$TEST</td>" >> $HTML_FILE
    echo -n "$TEST " >> temp.dat
    grep -m1 "Notification: Performance of $PHASE: time" $FILE | grep -o -P '(?<=: time).*' | grep -o -E '\-?[0-9]+(,[0-9]+)*(\.[0-9]+(e\-?[0-9]+)?)?( kB| MB| GB| TB)?' | while read LINE
    do
      echo -n "<td>$LINE</td>" >> $HTML_FILE
      # handle units
      LINE=$(echo $LINE | sed '
        s/[eE]+*/\*10\^/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) kB/\1*1000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) MB/\1*1000000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) GB/\1*1000000000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) TB/\1*1000000000000/g' | bc -l)
      echo -n "$LINE " >> temp.dat
    done # LINE
    echo >> temp.dat
    echo -n "</tr>" >> $HTML_FILE
  done # TEST
  gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
    set key right bottom;
    set grid;
    set notitle;
    set output 'summary/$TEST_CLASS/plot-$ID.png';
    set pointsize 1;
    set xrange [0:*];
    set yrange [0:*];
    set ytics;
    set y2range [0:*];
    set y2tics;
    plot 'temp.dat' using 1:2 title 'time' with linespoints, 'temp.dat' using 1:4 title 'allocations' with linespoints axes x1y2"
  echo "</table>" >> $HTML_FILE
done # PHASE

# generate summary plots
gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
  set key right bottom;
  set grid;
  set notitle;
  set output 'summary/$TEST_CLASS/plot-0.png';
  set pointsize 1;
  set xrange [0:*];
  set yrange [0:*];
  set ytics;
  set y2range [0:*];
  set y2tics;
  plot 'temp.dat' using 1:3 title 'time' with linespoints, 'temp.dat' using 1:5 title 'allocations' with linespoints axes x1y2"
echo "</body></html>" >> $HTML_FILE