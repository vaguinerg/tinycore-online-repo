sudo apt-get update -y
sudo apt-get install -y jq

#need to manually map *.tcz.* files to skip *.tcz.zsync and md5
rsync -av --size-only --delete --prune-empty-dirs --include="*/*/tcz/*.tcz.dep" --include="*/*/tcz/*.tcz.list" --include="*/*/tcz/*.tcz.info" --include="*/*/tcz/*.tcz.tree" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux

mapfile -t tcvers < <(find tinycorelinux -mindepth 2 -maxdepth 2 -type d -exec sh -c 'echo "$(basename $(dirname {})) $(basename {})"' \;)

for item in "${tcvers[@]}"; do
  version=$(echo "$tcvers" | awk '{print $1}')
  arch=$(echo "$tcvers" | awk '{print $2}')
  [ -d "data/$version/$arch" ] || mkdir -p "data/$version/$arch"
  output_directory="data/$version/$arch"
  input_directory="tinycorelinux/$version/$arch/tcz"
  
  find $input_directory/*.list -maxdepth 1 -type f -exec basename {} \; | sed 's/\.list//' > "$output_directory/tczlist"
  
  for type in provides sizelist taglist; do
	echo "{" > "$output_directory/$type"
	for file in $input_directory/*.list; do
             name=$(basename "$file" .list)
             case $type in
                provides)
		    echo "\"$name\": [" >> "$output_directory/provides"
		    while IFS= read -r line || [ -n "$line" ]; do
		        echo "\"$line\"," >> "$output_directory/provides"
		    done < "${name}.list"
		    echo "]," >> "$output_directory/provides"
                    ;;
                sizelist)
		    size=$(grep -Eo 'Size:[[:space:]]+[0-9.]+[[:alpha:]]+' "${name}.info" | awk '{print $2}')
		    echo "\"$name\": \"$size\"," >> "$output_directory/sizelist"
                    ;;
                taglist)
		    tags=$(grep -Eo 'Tags:[[:space:]]+.+' "${name}.info" | awk '{$1=""; print $0}' | tr -s ' ' | sed 's/^[[:space:]]//')
		    echo "\"$name\": [\"$tags\"]," >> "$output_directory/taglist"
                    ;;
            esac
	done
 	echo "}" >> "$output_directory/$type"
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
