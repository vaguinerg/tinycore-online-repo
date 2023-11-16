sudo apt-get update -y
sudo apt-get install -y jq

#need to manually map *.tcz.* files to skip *.tcz.zsync and md5
rsync -av --size-only --delete --prune-empty-dirs --include="*/*/tcz/*.tcz.dep" --include="*/*/tcz/*.tcz.list" --include="*/*/tcz/*.tcz.info" --include="*/*/tcz/*.tcz.tree" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux
result=$(rsync -av --list-only --include="*/*/tcz/*.tcz" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux)

for version_dir in tinycorelinux/*.x; do
	version=$(basename "$version_dir")
	for arch_dir in tinycorelinux/$version/*; do
		arch=$(basename "$arch_dir")
		mkdir -p data/$version/$arch/
  		output_directory="data/$version/$arch"
		find tinycorelinux/$version/$arch/tcz/*.list -maxdepth 1 -type f -exec basename {} \; | sed 's/\.list//' > "$output_directory/tczlist"
		
  		#I couldn't get JQ to work, so I'm going to use this aberration that is working.
		echo "{" > "$output_directory/provides"
		for file in tinycorelinux/$version/$arch/tcz/*.list; do
		    name=$(basename "$file" .list)
		    echo "\"$name\": [" >> "$output_directory/provides"
		    while IFS= read -r line || [ -n "$line" ]; do
		        echo "\"$line\"," >> "$output_directory/provides"
		    done < "$file"
		    echo "]," >> "$output_directory/provides"
		done
		echo "}" >> "$output_directory/provides"

  		echo "{" > "$output_directory/sizelist"
		for file in tinycorelinux/$version/$arch/tcz/*.info; do
		    size="NA"
		    name=$(basename "$file" .info)
		    IFS=$'\n'; for line in $result; do
			if [ "$(echo $line | awk '{print $5}')" == "$version/$arch/tcz/$name" ]; then
			  size=$(echo $line | awk '{print $2}')
			fi
		    done
		    #size=$(grep -Eo 'Size:[[:space:]]+[0-9.]+[[:alpha:]]+' "$file" | awk '{print $2}')
		    echo "\"$name\": \"$size\"," >> "$output_directory/sizelist"
		done
		echo "}" >> "$output_directory/sizelist"
		
		echo "{" > "$output_directory/taglist"
		for file in tinycorelinux/$version/$arch/tcz/*.info; do
		    name=$(basename "$file" .info)
		    tags=$(grep -Eo 'Tags:[[:space:]]+.+' "$file" | awk '{$1=""; print $0}' | tr -s ' ' | sed 's/^[[:space:]]//')
		    echo "\"$name\": [\"$tags\"]," >> "$output_directory/taglist"
		done
		echo "}" >> "$output_directory/taglist"
 	done
done

echo "{" > "site-data/versions"
for version in ./data/*/; do
    version_name=$(basename "$version")
    echo "\"$version_name\": [" >> "site-data/versions"
    for arch in "$version"/*/; do
        arch_name=$(basename "$arch")
        echo "\"$arch_name\"," >> "site-data/versions"
    done
    echo "]," >> "site-data/versions"
done
echo "}" >> "site-data/versions"

git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update"
git push
