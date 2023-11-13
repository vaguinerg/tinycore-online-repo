echo tst >> xd
git config --global user.name 'GitHub Actions'
git config --global user.email 'actions@github.com'
git add .
git commit -m "Update ISO file"
git push
