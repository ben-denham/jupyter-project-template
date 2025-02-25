#!/bin/bash

# Clear outputs from voila-notebooks
shopt -s globstar
for notebook_file in `find notebooks/voila/ -type f -name "*.ipynb"`; do
    uv run jupyter nbconvert --clear-output --inplace "$notebook_file"
done
