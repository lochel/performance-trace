#!/bin/bash
# author: Lennart Ochel

echo "Generating reports"

TESTS=$(ls *.mos | rev | cut -c 5- | rev)

for TEST in $TESTS
do
  mkdir -p summary/$TEST/
  HTML_FILE=summary/$TEST/$TEST.html
  echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body>" > $HTML_FILE
  echo "<h1>OpenModelica - Performance Trace Overview</h1>" >> $HTML_FILE
  echo "model: $TEST" >> $HTML_FILE

  HTML_FILE_SUMMARY=summary/$TEST/$TEST-summary.html
  echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body>" > $HTML_FILE_SUMMARY
  echo "<h1>OpenModelica - Performance Trace Overview</h1>" >> $HTML_FILE_SUMMARY
  echo "model: $TEST" >> $HTML_FILE_SUMMARY

  FILES=$(ls dumps/$TEST/$TEST-*.txt | sort -n | tail -n20)
  FIRST_FILE=$(echo $FILES | awk '{print $1;}')
  ID=0

  echo "<h2>Summary</h2>" >> $HTML_FILE
  echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE
  echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE
  #echo "<img src=\"$TEST-free-$ID.png\">" >> $HTML_FILE

  echo "<h2>Summary</h2>" >> $HTML_FILE_SUMMARY
  echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE_SUMMARY
  echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE_SUMMARY
  #echo "<img src=\"$TEST-free-$ID.png\">" >> $HTML_FILE_SUMMARY

  grep -o -P '(?<=Notification: Performance of ).*(?=: time)' $FIRST_FILE | while read PHASE
  do
    echo "<h2>$PHASE</h2>" >> $HTML_FILE
    echo "<h2>$PHASE</h2>" >> $HTML_FILE_SUMMARY
    ID=$((ID+1))
    echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE
    echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE
    #echo "<img src=\"$TEST-free-$ID.png\">" >> $HTML_FILE
    echo "<img src=\"$TEST-time-$ID.png\">" >> $HTML_FILE_SUMMARY
    echo "<img src=\"$TEST-allocations-$ID.png\">" >> $HTML_FILE_SUMMARY
    #echo "<img src=\"$TEST-free-$ID.png\">" >> $HTML_FILE_SUMMARY
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
    gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-time-$ID.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:2 notitle with lines;"
    gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-allocations-$ID.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:4 notitle with lines;"
    #gnuplot -p -e "set title 'free' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-free-$ID.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:6 notitle with lines;"

    echo "</table>" >> $HTML_FILE
  done # PHASE

  # generate summary plots
  gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-time-0.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:3 notitle with lines;"
  gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-allocations-0.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:5 notitle with lines;"
  #gnuplot -p -e "set title 'free' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST/$TEST-free-0.png'; set xtics rotate; set timefmt '%s'; set format x '%m/%d-%y'; set xdata time; set yrange [0:*]; set grid; plot 'temp.dat' using 1:7 notitle with lines;"

  echo "</body></html>" >> $HTML_FILE
  echo "</body></html>" >> $HTML_FILE_SUMMARY
done # TEST
