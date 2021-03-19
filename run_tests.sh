#!/bin/bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

PYTHON_REQUIREMENTS_INSTALLED=false

function setup_python {
  python3 -m venv .env
  source .env/bin/activate
  if [[ "$PYTHON_REQUIREMENTS_INSTALLED" = false ]]
  then
    echo "Installing Python requirements"
    pip3 install -r requirements.txt -q
    PYTHON_REQUIREMENTS_INSTALLED=true
  fi
}

# Fixes lint
function run_py_lint_fix {
  setup_python
  echo "#### Fixing Python code"
  yapf -r -i -p --style=google util/ scripts/ import-automation/
}

# Tests Python code style
function run_py_lint_test {
  setup_python
  echo "#### Testing Python lint"
  if ! yapf -r --diff -p --style=google util/ scripts/ import-automation/; then
    echo "Fix lint errors by running ./run_test.sh -f"
    exit 1
  fi
}

# Run Python tests. Requires folder to run tests in specified in $1.
function run_py_test {
  if [ $# -eq 0 ]
  then
    echo "Please specify a folder to run tests in"
    exit 1
  fi
  setup_python
  echo "#### Testing Python code in $1"
  python3 -m unittest discover -v -s $1 -p *_test.py
}

function help {
  echo "Usage: $0 -rplusiaf"
  echo "-r       Install Python requirements"
  echo "-l       Test lint on Python code"
  echo "-p       Run Python tests in specified folder, e.g. ./run_test.sh -p util"
  echo "-a       Run all tests"
  echo "-f       Fix lint"
  exit 1
}

while getopts rp:lusiaf OPTION; do
  case $OPTION in
    r)
        echo "### Installing Python requirements"
        setup_python
        ;;
    l)
        echo "### Testing lint"
        run_py_lint_test
        ;;
    p)
        echo "### Running Python tests in ${OPTARG}"
        run_py_test ${OPTARG}
        ;;
    f)
        echo "### Fixing lint errors"
        run_py_lint_fix
        ;;
    a)
        echo "### Running all tests"
        run_py_test "util/"
        run_py_test "scripts/"
        run_py_test "import-automation/"
        run_py_lint_test
        ;;
    *)
        help
    esac
done

if [ $OPTIND -eq 1 ]
then
  help
fi