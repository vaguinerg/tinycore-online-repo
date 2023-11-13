#need to manually map *.tcz.* files to skip *.tcz.zsync and md5
rsync -av --delete --prune-empty-dirs --include="*/*/tcz/*.tcz.dep" --include="*/*/tcz/*.tcz.list" --include="*/*/tcz/*.tcz.info" --include="*/*/tcz/*.tcz.tree" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux

for version_dir in tinycorelinux/*.x; do
	version=$(basename "$version_dir")
	for arch_dir in tinycorelinux/$version/*; do
		arch=$(basename "$arch_dir")
		mkdir -p data/$version/$arch/
  		output_directory="data/$version/$arch"
		find tinycorelinux/$version/$arch/tcz/*.list -maxdepth 1 -type f -exec basename {} \; | sed 's/\.list//' > "$output_directory/tczlist"
		
  		#I couldn't get JQ to work, so I'm going to use this aberration that is working.
		echo "{" > "$output_directory/provides.json"
		for file in tinycorelinux/$version/$arch/tcz/*.list; do
		    name=$(basename "$file" .list)
		    echo "\"$name\": [" >> "$output_directory/provides.json"
		    while IFS= read -r line || [ -n "$line" ]; do
		        echo "\"$line\"," >> "$output_directory/provides.json"
		    done < "$file"
		    echo "]," >> "$output_directory/provides.json"
		done
		echo "}" >> "$output_directory/provides.json"
 	done
done


git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update"
git push
