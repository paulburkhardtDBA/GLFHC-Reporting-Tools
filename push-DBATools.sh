# ref https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
# Set Directory for code.
cd "D:\GitHub\DBATools"
# Set date/time variable (for commits)
CURRENTDATE=`date +"%Y-%m-%d %T"`
# Adds the file to your local repository and stages it for commit. To unstage a file, use 'git reset HEAD YOUR-FILE'.
git add .
# Commits the tracked changes and prepares them to be pushed to a remote repository. To remove this commit and modify the file, use 'git reset --soft HEAD~1' and commit and add the file again.
git commit -m "Auto-Commit $CURRENTDATE"
# Pushes the changes in your local repository up to the remote repository you specified as the origin.
git push origin
#exit program
exit
