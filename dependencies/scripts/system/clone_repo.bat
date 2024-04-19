@echo off

SET repo_path=%1
SET repo_name=%2
SET repo_url_github=%3
SET repo_version=%4
SET start_script=%5


IF exist %repo_path%\%repo_name%\%start_script% (
  echo Repository is already cloned
) ELSE (
  echo Cloning git repository into %repo_path%
  cd %repo_path%
  git clone %repo_url_github% %repo_name%
  cd %repo_name%
  echo Installing version: %repo_version%
  git reset --hard %repo_version%
  git -C %repo_path%\%repo_name% pull origin %repo_version%
)
