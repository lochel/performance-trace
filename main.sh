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
git fetch --recurse-submodules
COMMITS=$(git log HEAD..origin/HEAD --format='%H' | tac)
for COMMIT in $COMMITS
do
  echo $COMMIT
  git checkout $COMMIT
  git submodule update --recursive

  VERSION_OpenModelica="OpenModelica $(git describe --match "v*.*" --always)"
  cd OMCompiler
  VERSION_OMCompiler="OMCompiler $(git describe --match "v*.*" --always)"
  cd ..
  echo $VERSION_OpenModelica
  echo $VERSION_OMCompiler
done
cd ..
