#!/bin/bash
# author: Lennart Ochel

echo "Generating reports"

TESTS=$(ls *.mos | rev | cut -c 5- | rev)

for TEST in $TESTS
do
  mkdir -p summary/$TEST/

  HTML_FILE_SUMMARY=summary/$TEST/index.html
  echo "<html><head><title>Performance Trace</title><body><center>" > $HTML_FILE_SUMMARY
  echo "<h1>OpenModelica - Performance Trace</h1>" >> $HTML_FILE_SUMMARY
  echo "model: $TEST" >> $HTML_FILE_SUMMARY

  FILES=$(ls dumps/$TEST/$TEST-*.txt | sort -n)
  FIRST_FILE=$(echo $FILES | awk '{print $1;}')
  ID=0

  echo "<h2>Summary</h2>" >> $HTML_FILE_SUMMARY
  echo "<img src=\"plot-$ID.png\">" >> $HTML_FILE_SUMMARY

  grep -o -P '(?<=Notification: Performance of ).*(?=: time)' $FIRST_FILE | while read PHASE
  do
    ID=$((ID+1))

    HTML_FILE=summary/$TEST/plot-$ID.html
    echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body><center>" > $HTML_FILE
    echo "<h1>OpenModelica - Performance Trace Overview</h1>" >> $HTML_FILE
    echo "model: $TEST (<a href=\"./index.html\">back to summary</a>)" >> $HTML_FILE
    echo "<h2>$PHASE</h2>" >> $HTML_FILE
    echo "<img src=\"plot-$ID.png\">" >> $HTML_FILE

    echo "<h2>$PHASE</h2>" >> $HTML_FILE_SUMMARY
    echo "<a href=\"./plot-$ID.html\"><img src=\"plot-$ID.png\"></a>" >> $HTML_FILE_SUMMARY
    echo "<table border=\"1\">" >> $HTML_FILE
    echo "<td>date</td><td>OpenModelica</td><td>OMCompiler</td><td>time</td><td>accumulated time</td><td>allocations</td><td>accumulated allocations</td><td>free</td><td>accumulated free</td>" >> $HTML_FILE
    echo -n > temp.dat
    for FILE in $FILES
    do
      TIMESTAMP=$(grep -o -m1 -P '(?<=OpenModelica-timestamp: ).*' $FILE)
      echo -n "<tr><td>$(date -d @$TIMESTAMP +'%m/%d-%y %H:%M')</td><td><a href=\"https://github.com/OpenModelica/OpenModelica/commit/$(grep OpenModelica- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep -o -m1 -P '(?<=OpenModelica-).*' $FILE)</a></td><td><a href=\"https://github.com/OpenModelica/OMCompiler/commit/$(grep OMCompiler- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep -o -m1 -P '(?<=OMCompiler-).*' $FILE)</a></td>" >> $HTML_FILE
      echo -n "$TIMESTAMP " >> temp.dat
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
    done # FILE
      gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
        set format x '%m/%d-%y';
        set key right bottom;
        set grid;
        set title '$PHASE';
        set output 'summary/$TEST/plot-$ID.png';
        set pointsize 1;
        set timefmt '%s';
        set xlabel '$TEST';
        set xdata time;
        set ylabel 'time [s]';
        set yrange [0:*];
        set ytics;
        set y2label 'allocations [B]';
        set y2range [0:*];
        set y2tics;
        plot 'temp.dat' using 1:2 title 'time' with lines, 'temp.dat' using 1:4 title 'allocations' with lines axes x1y2"

    echo "</table>" >> $HTML_FILE
    echo "</center></body></html>" >> $HTML_FILE
  done # PHASE

  # generate summary plots
  gnuplot -p -e "set terminal pngcairo size 1200,400 enhanced font 'Verdana,10';
    set format x '%m/%d-%y';
    set key right bottom;
    set grid;
    set title 'OpenModelica Compiler';
    set output 'summary/$TEST/plot-0.png';
    set pointsize 1;
    set timefmt '%s';
    set xlabel '$TEST';
    set xdata time;
    set ylabel 'time [s]';
    set yrange [0:*];
    set ytics;
    set y2label 'allocations [B]';
    set y2range [0:*];
    set y2tics;
    plot 'temp.dat' using 1:3 title 'time' with lines, 'temp.dat' using 1:5 title 'allocations' with lines axes x1y2"

  echo "</center></body></html>" >> $HTML_FILE_SUMMARY
done # TEST
