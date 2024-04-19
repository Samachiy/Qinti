#! /usr/bin/bash

target_path=$1
python_version=$2


echo 'Setting python enviroment version: ' "${python_version}"
if ! command -v pyenv &> /dev/null
then
    echo 'Installing pyenv'
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

cd "${target_path}"
pyenv global system
pyenv install -s "${python_version}"
pyenv local "${python_version}"

echo 'Successfully set python version at: ' "${target_path}"
