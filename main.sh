#!/bin/bash
# author: Lennart Ochel

# clone OpenModelica
if [ ! -d "OpenModelica" ]; then
  git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica
  cd OpenModelica
  git submodule update --init --recursive libraries OMCompiler common
  cd ..
fi

# find new commits
cd OpenModelica
COMMITS=$(git log HEAD..origin/HEAD --format='%H' | tac)
for COMMIT in $COMMITS
do
  echo $COMMIT
done
