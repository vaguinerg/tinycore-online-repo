#need to manually map *.tcz.* files to skip *.tcz.zsync and md5
rsync -av --delete --prune-empty-dirs --include="*/*/tcz/*.tcz.dep" --include="*/*/tcz/*.tcz.list" --include="*/*/tcz/*.tcz.info" --include="*/*/tcz/*.tcz.tree" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux
git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update"
git push
