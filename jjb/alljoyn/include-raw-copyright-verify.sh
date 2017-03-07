: BUILD DESCRIPTION : GERRIT_CHANGE_OWNER_EMAIL=$GERRIT_CHANGE_OWNER_EMAIL, BUILD_USER_EMAIL=$BUILD_USER_EMAIL, GERRIT_BRANCH=$GERRIT_BRANCH, GIT_COMMIT=$GIT_COMMIT

export PATH=$PATH:/usr/local/bin
: INFO git log
git log -1

export

ES=0

# Modified files.
for fn in `git show --pretty="format:" --name-status HEAD| grep -v "^A" | grep -Ei "\.[chm]$|\.c[cs]$|\.cpp$|\.mm$|\.ino$|\.py$|\.sh$|\.java$|SConscript$|SConstruct$" | awk '{print $2}'|grep -v "^external"`; do
  if [ -f $fn ]; then
    FES=`head -40 $fn|grep "Copyright AllSeen Alliance. All rights reserved." | wc -l`
    if [ "$FES" != "1" ]; then
      echo $fn fails copyright check. Regex for a valid copyright will be in the form of "Copyright AllSeen Alliance. All rights reserved." for modified files>>copyright-modified-fail.log
      ES=1
    else
      echo $fn passes copyright check>>copyright-pass.log
    fi
  fi
done

# Added files.
for fn in `git show --pretty="format:" --name-status HEAD| grep "^A" | grep -Ei "\.[chm]$|\.c[cs]$|\.cpp$|\.mm$|\.ino$|\.py$|\.sh$|\.java$|SConscript$|SConstruct$" | awk '{print $2}'|grep -v "^external"`; do
  if [ -f $fn ]; then
    FES=`head -40 $fn|grep "Copyright AllSeen Alliance. All rights reserved." | wc -l`
    if [ "$FES" != "1" ]; then
      echo $fn fails copyright check. Valid copyright regex "Copyright AllSeen Alliance. All rights reserved." for added files>>copyright-added-fail.log
      ES=1
    else
      echo $fn passes copyright check>>copyright-pass.log
    fi
  fi
done

if [ "$ES" -eq "1" ]; then
  echo Check `ls *fail.log` for files that failed copyright check.
  exit $ES
fi
