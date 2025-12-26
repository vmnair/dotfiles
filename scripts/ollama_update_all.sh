#! /bin/bash
# Usage: ./ollama_update_all.sh

for n in $(ollama ls | awk '(NR > 1) {print $1}')
do 
    echo ollama pull ${n}
    ollama pull ${n}
    echo
done
