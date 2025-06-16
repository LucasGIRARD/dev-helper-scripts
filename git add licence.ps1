cd test/htdocs

# Start interactive rebase from the beginning
git rebase -i --root

# In the editor that opens:
# Change 'pick' to 'edit' for the first commit
# Save and close

cp ../../LICENCE.md

# Add your file
git add LICENCE.md
git commit --amend --no-edit

# Continue the rebase
git rebase --continue

git push origin +main