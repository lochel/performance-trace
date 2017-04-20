#!/bin/bash
# author: Lennart Ochel

git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica
cd OpenModelica
git submodule update --init --recursive libraries testsuite OMCompiler common
