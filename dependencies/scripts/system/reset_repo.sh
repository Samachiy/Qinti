#! /usr/bin/bash

repo_path=$1
repo_name=$2
repo_url_github=$3
repo_version=$4
start_script=$5

if [[ -f "${repo_path}"/"${repo_name}"/"${start_script}" ]]
then
    echo "Reseting git repository to " "${repo_url_github}" " at " "${repo_path}"/"${repo_name}"
    cd "${repo_path}"/"${repo_name}"
    git remote set-url origin "${repo_url_github}"
    git reset --hard origin/master
    rm -fr .git/rebase-merge
    git checkout "${repo_version}"
else
    echo "Cloning git repository into " "${repo_path}"
    cd "${repo_path}"
    git clone "${repo_url_github}"
    cd "${repo_name}"
fi

echo "Installing version: " "${repo_version}"
git reset --hard "${repo_version}"
git -C "${repo_path}/${repo_name}" pull origin "${repo_version}"


while getopts 'E' OPTION; do
  case "$OPTION" in
    E)
      echo "Deleting virtual enviroment"
      rm -fr venv
      ;;
  esac
done
