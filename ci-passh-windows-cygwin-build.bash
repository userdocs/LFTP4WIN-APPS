#!/usr/bin/env bash

HOME="$(pwd)"

if [[ ${1} =~ ^/ ]]; then
	cygwin_path="${1}"
else
	cygwin_path="${HOME}/${1:-cygwin}"
fi
source_repo="${2:-https://github.com/clarkwang/passh.git}"
source_branch="${3:-master}"

printf '%b\n' " \e[93m\U25cf\e[0m Build path = ${HOME}"
printf '\n%b\n' " \e[93m\U25cf\e[0m parameters = ${*}"
printf '\n%b\n' " \e[93m\U25cf\e[0m cygwin_path = ${cygwin_path}"
printf '\n%b\n' " \e[93m\U25cf\e[0m source_repo = ${source_repo}"
printf '\n%b\n' " \e[93m\U25cf\e[0m source_branch = ${source_branch}"

printf '\n%b\n\n' " \e[94m\U25cf\e[0m Cloning passh git repo"

[[ -d "$HOME/passh_build" ]] && rm -rf "$HOME/passh_build"

printf '\n%b\n\n' " \e[94m\U25cf\e[0m git clone --no-tags --single-branch --branch ${source_branch} --shallow-submodules --recurse-submodules -j$(nproc) --depth 1 ${source_repo} $HOME/passh_build"
git clone --no-tags --single-branch --branch "${source_branch}" --shallow-submodules --recurse-submodules -j"$(nproc)" --depth 1 "${source_repo}" "$HOME/passh_build"

cd "$HOME/passh_build" || exit 1

printf '\n%b\n\n' " \e[94m\U25cf\e[0m Repo Info"

git remote show origin

printf '\n%b\n' " \e[92m\U25cf\e[0m Setting passh version to file passh_version"
sed -rn 's|char \* const VERSION_ = "(.*)";|\1|p' passh.c > "$HOME/passh_version"

printf '\n%b\n\n' " \e[94m\U25cf\e[0m building passh"

cc -o passh passh.c

mkdir -p "${HOME}/lftp4win_bin"
cp -f "passh.exe" "$HOME/lftp4win_bin"

printf '\n%b\n' " \e[94m\U25cf\e[0m Copy dll dependencies"
[[ -f "${cygwin_path}/bin/cygwin1.dll" ]] && cp -f "${cygwin_path}/bin/cygwin1.dll" "$HOME/lftp4win_bin"
printf '\n%b\n' " \e[92m\U25cf\e[0m Copied the dll dependencies"
