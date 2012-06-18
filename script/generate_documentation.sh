#!/bin/bash

echo "Removing each file in the tmp directory..."
tmp_files=`find tmp -type f`

for tmp_file in $tmp_files
do
   if [[ -e "$tmp_file" ]]
   then
      echo "   Removing $tmp_file..."
      rm $tmp_file
   fi
done

echo "Generating YARD documentation and diagram..."
yardoc
yard graph --full | dot -T svg -o doc/diagrams/class_diagram.svg

echo "Copying to online documenation site ualberta.ca/~morrill/doc."
scp -r doc morrill@gpu.srv.ualberta.ca:~/public_html/
