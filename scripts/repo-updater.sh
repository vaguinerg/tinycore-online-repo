rsync -av --delete --include="*/*/tcz/*.tcz.*" --include="*/" --exclude="*" repo.tinycorelinux.net::tc ./tinycorelinux
git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update"
git push
