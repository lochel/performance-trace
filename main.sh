#!/bin/bash
# author: Lennart Ochel

NUM_THREADS=12

# clone OpenModelica
if [ ! -d "OpenModelica" ]; then
  git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica
  cd OpenModelica
  git submodule update --init --recursive libraries OMCompiler common
  cd ..
fi

TESTS=$(ls *.mos | rev | cut -c 5- | rev)
for TEST in $TESTS
do
  mkdir -p dumps/$TEST/
done

export OPENMODELICAHOME=$PWD/OpenModelica/build/
export OPENMODELICALIBRARY=$OPENMODELICAHOME/lib/omlibrary/

# find all new commits
cd OpenModelica
git fetch --recurse-submodules
COMMITS=$(git log HEAD..origin/HEAD --format='%H' | tac)
cd ..

for COMMIT in $COMMITS
do
  echo Start testing OpenModelica $COMMIT

  # checkout $COMMIT
  cd OpenModelica
  git checkout $COMMIT
  git submodule update --recursive

  VERSION_OpenModelica="OpenModelica-$(git describe --match "v*.*" --always)"
  cd OMCompiler
  VERSION_OMCompiler="OMCompiler-$(git describe --match "v*.*" --always)"
  cd ..

  # build OpenModelica
  make clean
  autoconf
  ./configure CC=gcc CXX=g++ 'OMPCC=gcc -fopenmp' 'CFLAGS=-O2 -march=native' --without-omc --with-omlibrary=core
  time make omc omlibrary-all -j$NUM_THREADS
  cd ..

  echo $VERSION_OpenModelica
  echo $VERSION_OMCompiler
  ./OpenModelica/build/bin/omc --version

  # run tests
  for TEST in $TESTS
  do
    echo Start testing $TEST with OpenModelica $COMMIT
    mkdir -p temp/
    cd temp
    ../loadControl.sh 0.5
    DUMP_FILE=../dumps/$TEST/$TEST-$VERSION_OpenModelica.txt
    date >> $DUMP_FILE
    echo $VERSION_OpenModelica >> $DUMP_FILE
    echo $VERSION_OMCompiler >> $DUMP_FILE
    ../OpenModelica/build/bin/omc --version >> $DUMP_FILE
    ../OpenModelica/build/bin/omc ../$TEST.mos >> $DUMP_FILE
    cd ..
    rm temp -rf
  done # TEST

  # generate summary
  ./generateSummary.sh && rm ../public_html/summary/ -rf && cp summary/ ../public_html/ -rf
done # COMMIT

# generate summary
#./generateSummary.sh && cp summary/ ../public_html/ -rf
