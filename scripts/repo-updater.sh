#need to manually map *.tcz.* files to skip *.tcz.zsync and md5
rsync -av --delete --prune-empty-dirs --include="*/*/tcz/*.tcz.dep" --include="*/*/tcz/*.tcz.list" --include="*/*/tcz/*.tcz.info" --include="*/*/tcz/*.tcz.tree" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux

for version_dir in tinycorelinux/*.x; do
	version=$(basename "$version_dir")
	for arch_dir in tinycorelinux/$version/*; do
		arch=$(basename "$arch_dir")
		mkdir -p data/$version/$arch/
		find tinycorelinux/$version/$arch/tcz/*.list -maxdepth 1 -type f -exec basename {} \; | sed 's/\.list//' > data/$version/$arch/tczlist
	done
done


git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update"
git push
