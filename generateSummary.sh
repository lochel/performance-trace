#!/bin/bash
# author: Lennart Ochel

TEST=Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot
mkdir -p summary

filename=summary/$TEST.html
echo "<html><head><title>OpenModelica - Performance Trace Overview</title><body>" > $filename
echo "<h1>OpenModelica - Performance Trace Overview</h1>" >> $filename
echo "model: $TEST" >> $filename

files=$(ls dumps/$TEST-v1.12.0-dev-* | sort -n)
firstFile=$(echo $files | awk '{print $1;}')
phases=$(grep "Notification: Performance of" $firstFile | grep -o -P '(?<=Notification: Performance of ).*(?=: time)')
id=0

echo "<h2>Summary</h2>" >> $filename
echo "<img src=\"$TEST-time-$id.png\">" >> $filename
echo "<img src=\"$TEST-allocations-$id.png\">" >> $filename
grep "Notification: Performance of" $firstFile | grep -o -P '(?<=Notification: Performance of ).*(?=: time)' | while read phase
do
  echo "<h2>$phase</h2>" >> $filename
  id=$((id+1))
  echo "<img src=\"$TEST-time-$id.png\">" >> $filename
  echo "<img src=\"$TEST-allocations-$id.png\">" >> $filename
  echo "<table border=\"1\">" >> $filename
  echo "<td>OpenModelica</td><td>OMCompiler</td><td>time</td><td></td><td>allocations</td><td></td><td>free</td><td></td>" >> $filename
  echo -n > temp.dat
  for file in $files
  do
    echo -n "<tr><td><a href=\"https://github.com/OpenModelica/OpenModelica/commit/$(echo $file | grep -o -P '(?<=-g).*(?=.txt)')\">$(echo $file | grep -o -P '(?<='$TEST'-).*(?=.txt)')</a></td><td><a href=\"https://github.com/OpenModelica/OMCompiler/commit/$(grep OMCompiler $file | head -n1 | cut -b 12- | grep -o -P '(?<=-g).*')\">$(grep OMCompiler $file | head -n1 | cut -b 12-)</a></td>" >> $filename
    grep "Notification: Performance of $phase: time" $file | grep -o -E '\-?[0-9]+(,[0-9]+)*(\.[0-9]+(e\-?[0-9]+)?)?( kB| MB| GB| TB)?' | while read line
    do
      echo -n "<td>$line</td>" >> $filename
      # handle units
      line=$(echo $line | sed '
        s/[eE]+*/\*10\^/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) kB/\1*1000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) MB/\1*1000000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) GB/\1*1000000000/g;
        s/\([0-9][0-9]*\(\.[0-9]\+\)\?\) TB/\1*1000000000000/g' | bc -l)
      echo -n "$line " >> temp.dat
    done
    echo >> temp.dat
    echo -n "</tr>" >> $filename
  done
  gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST-time-$id.png'; set yrange [0:*]; plot 'temp.dat' using 1 notitle with linespoints;"
  gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST-allocations-$id.png'; set yrange [0:*]; plot 'temp.dat' using 3 notitle with linespoints;"

  echo "</table>" >> $filename
done

# generate summary plots
gnuplot -p -e "set title 'time' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST-time-0.png'; set yrange [0:*]; plot 'temp.dat' using 2 notitle with linespoints;"
gnuplot -p -e "set title 'allocations' font ',14' textcolor rgbcolor 'royalblue'; set pointsize 1; set terminal pngcairo size 480,360 enhanced font 'Verdana,10'; set output 'summary/$TEST-allocations-0.png'; set yrange [0:*]; plot 'temp.dat' using 4 notitle with linespoints;"

echo "</body></html>" >> $filename
