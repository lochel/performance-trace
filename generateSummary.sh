#!/bin/bash
# author: Lennart Ochel

TESTS=$(ls *.mos | rev | cut -c 5- | rev)
for TEST in $TESTS
do
  mkdir -p summary/$TEST/
done

for TEST in $TESTS
do
  HTML_FILE=summary/$TEST/$TEST.html
  echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body>" > $HTML_FILE
  echo "<h1>OpenModelica - Performance Trace Overview</h1>" >> $HTML_FILE
  echo "model: $TEST" >> $HTML_FILE

  FILES=$(ls dumps/$TEST/$TEST-*.txt | sort -n)
  FIRST_FILE=$(echo $FILES | awk '{print $1;}')
  ID=0

  echo "<h2>Summary</h2>" >> $HTML_FILE
  echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE
  echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE
  grep "Notification: Performance of" $FIRST_FILE | grep -o -P '(?<=Notification: Performance of ).*(?=: time)' | while read PHASE
  do
    echo "<h2>$PHASE</h2>" >> $HTML_FILE
    ID=$((ID+1))
    echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE
    echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE
    echo "<table border=\"1\">" >> $HTML_FILE
    echo "<td>OpenModelica</td><td>OMCompiler</td><td>time</td><td></td><td>allocations</td><td></td><td>free</td><td></td>" >> $HTML_FILE
    echo -n > temp.dat
    for FILE in $FILES
    do
      echo -n "<tr><td><a href=\"https://github.com/OpenModelica/OpenModelica/commit/$(grep OpenModelica- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep OpenModelica- $FILE | head -n1 | grep -o -P '(?<=OpenModelica-).*')</a></td><td><a href=\"https://github.com/OpenModelica/OMCompiler/commit/$(grep OMCompiler- $FILE | head -n1 | grep -o -P '(?<=-g).*')\">$(grep OMCompiler- $FILE | head -n1 | grep -o -P '(?<=OMCompiler-).*')</a></td>" >> $HTML_FILE
      grep "Notification: Performance of $PHASE: time" $FILE | grep -o -E '\-?[0-9]+(,[0-9]+)*(\.[0-9]+(e\-?[0-9]+)?)?( kB| MB| GB| TB)?' | while read LINE
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
      done
      echo >> temp.dat
      echo -n "</tr>" >> $HTML_FILE
    done
    gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-time-$ID.png'; set yrange [0:*]; plot 'temp.dat' using 1 notitle with linespoints;"
    gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-allocations-$ID.png'; set yrange [0:*]; plot 'temp.dat' using 3 notitle with linespoints;"

    echo "</table>" >> $HTML_FILE
  done

  # generate summary plots
  gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-time-0.png'; set yrange [0:*]; plot 'temp.dat' using 2 notitle with linespoints;"
  gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-allocations-0.png'; set yrange [0:*]; plot 'temp.dat' using 4 notitle with linespoints;"

  echo "</body></html>" >> $HTML_FILE
done # TEST
