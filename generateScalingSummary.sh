#!/bin/bash
# author: Lennart Ochel

TEST_CLASS="ScalableTestSuite.Thermal.Advection.ScaledExperiments.SteamPipe"
echo "Generating scaling report for $TEST_CLASS"

mkdir -p summary/$TEST_CLASS
HTML_FILE=summary/$TEST_CLASS/index.html

echo "<html><head><title>Scaling Overview</title><body><center>" > $HTML_FILE
echo "<h1>OpenModelica - Scaling Overview</h1>" >> $HTML_FILE
echo "model class: $TEST_CLASS" >> $HTML_FILE

echo "<h2>Summary</h2>" >> $HTML_FILE
echo "<img src=\"plot-0.png\"><br />" >> $HTML_FILE

FIRST_FILE=$(ls dumps/$TEST_CLASS"_N_2560/"$TEST_CLASS"_N_"*.txt | sort -n | tail -n1)
TESTS=$(ls dumps/$TEST_CLASS* -d | grep -o -P '(?<=_N_).*' | sort -n)
VERSION="OpenModelica $(grep -o -m1 -P '(?<=OpenModelica-).*' $FIRST_FILE)"
MAX_SIZE=$(ls dumps/$TEST_CLASS* -d | grep -o -P '(?<=_N_).*' | sort -n | tail -n1)
ID=0

grep -o -P '(?<=Notification: Performance of ).*(?=: time)' $FIRST_FILE | while read PHASE
do
  # remove optional strings, e.g. (n=123)
  PHASE=$(echo $PHASE | grep -o -m1 -P '.*(?=\(n=)' || echo $PHASE)
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
    ESCAPED_PHASE=$(echo $PHASE | sed 's/(/\\(/g;s/)/\\)/g')
    grep -m1 -E "(Notification: Performance of $ESCAPED_PHASE)( \(n=[0-9]*\))?(: time)" $FILE | grep -o -P '(?<=: time).*' | grep -o -E '\-?[0-9]+(,[0-9]+)*(\.[0-9]+(e\-?[0-9]+)?)?( kB| MB| GB| TB)?' | while read LINE
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
  MAX_ALLOCATION=$(cut -d' ' -f2 temp.dat | sort -nr | head -n1)
  if [ "$MAX_ALLOCATION" = "0" ]; then
    LOGSCALE="xy"
  else
    LOGSCALE="xyy2"
  fi

  gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
    set key right bottom;
    set grid;
    set title '$PHASE [$VERSION]';
    set output 'summary/$TEST_CLASS/plot-$ID.png';
    set pointsize 1;
    set xlabel 'N [$TEST_CLASS]';
    set xrange [*:$MAX_SIZE];
    set ylabel 'time [s]';
    set yrange [*:*];
    set ytics;
    set y2label 'allocations [B]';
    set y2range [*:*];
    set y2tics;
    set logscale $LOGSCALE;
    plot 'temp.dat' using 1:2 title 'time' with linespoints, 'temp.dat' using 1:4 title 'allocations' with linespoints axes x1y2"
  echo "</table><br />" >> $HTML_FILE
done # PHASE

# generate summary plots
gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
  set key right bottom;
  set grid;
  set title '$VERSION';
  set output 'summary/$TEST_CLASS/plot-0.png';
  set pointsize 1;
  set xlabel 'N [$TEST_CLASS]';
  set xrange [*:$MAX_SIZE];
  set ylabel 'time [s]';
  set yrange [*:*];
  set ytics;
  set y2label 'allocations [B]';
  set y2range [*:*];
  set y2tics;
  set logscale xyy2;
  plot 'temp.dat' using 1:3 title 'time' with linespoints, 'temp.dat' using 1:5 title 'allocations' with linespoints axes x1y2"
echo "</center></body></html>" >> $HTML_FILE
