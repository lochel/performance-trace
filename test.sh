#!/bin/bash
# author: Lennart Ochel

if [ $# -gt 0 ]; then
  REVISIONS=$@
else
  REVISIONS=master
fi

cd OpenModelica
git fetch --recurse-submodules
git pull
cd ..

NUM_THREADS=12
TEST=Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot
mkdir -p dumps
export OPENMODELICAHOME=$PWD/OpenModelica/build/
export OPENMODELICALIBRARY=$OPENMODELICAHOME/lib/omlibrary/

for revision in $REVISIONS
do
  cd OpenModelica
  git checkout $revision
  git submodule update --recursive

  REVISION_OpenModelica=$(git describe --match "v*.*" --always)
  cd OMCompiler
  REVISION_OMCompiler=$(git describe --match "v*.*" --always)
  cd ../..

  filename=dumps/$TEST-$REVISION_OpenModelica.txt

  date > $filename
  echo OpenModelica $REVISION_OpenModelica >> $filename
  echo OMCompiler $REVISION_OMCompiler >> $filename

  # build OpenModelica
  cd OpenModelica
  make clean
  autoconf
  ./configure CC=gcc CXX=g++ 'OMPCC=gcc -fopenmp' 'CFLAGS=-O2 -march=native' --without-omc --with-omlibrary=core
  time make omc omlibrary-core -j$NUM_THREADS
  ./build/bin/omc --version >> ../$filename
  date >> ../$filename
  cd ..

  # run test model
  mkdir -p temp
  cd temp
  ../loadControl.sh 0.3 >> ../$filename
  date >> ../$filename
  ../OpenModelica/build/bin/omc ../$TEST.mos >> ../$filename
  cd ..

  # generate summary
  ./generateSummary.sh && cp summary/ ../public_html/ -rf
done
