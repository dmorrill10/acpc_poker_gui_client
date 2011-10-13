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

echo "Generating a tree with this app's file contents..."
tree . > extra_docs/temp_app_tree

echo "Generating tree for FileStructure documentation..."
sed 's/^/   /' extra_docs/temp_app_tree >> extra_docs/FileStructure

echo "Removing the temporary application tree file..."
rm -f extra_docs/temp_app_tree

echo "Generating YARD documentation and diagram..."
yardoc
yard graph --full | dot -T svg -o doc/diagrams/class_diagram.svg

echo "Copying to online documenation site ualberta.ca/~morrill/doc."
scp -r doc morrill@gpu.srv.ualberta.ca:~/public_html/
