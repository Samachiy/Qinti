#! /usr/bin/bash

repo_path=$1
repo_name=$2
repo_url_github=$3
repo_version=$4
start_script=$5

if [[ -f "${repo_path}"/"${repo_name}"/"${start_script}" ]]
then
    echo "Repository is already cloned"
    #cd "${repo_path}"
    #cd "${repo_name}"
    #echo "Setting version: " "${repo_version}"
    #git reset --hard "${repo_version}"
    #git -C "${repo_path}/${repo_name}" pull origin "${repo_version}"
else
    echo "Cloning git repository into " "${repo_path}"
    cd "${repo_path}"
    git clone "${repo_url_github}" "${repo_name}"
    cd "${repo_name}"
    echo "Installing version: " "${repo_version}"
    git reset --hard "${repo_version}"
    git -C "${repo_path}/${repo_name}" pull origin "${repo_version}"
fi

