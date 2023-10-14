#!/bin/bash
set -euxo pipefail


extra_hosts="$1"; shift || true


#
# set the extra hosts.

cat >>/etc/hosts <<EOF
$extra_hosts
EOF


#
# prevent apt-get et al from asking questions.

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' >/etc/sudoers.d/env_keep_apt
chmod 440 /etc/sudoers.d/env_keep_apt
export DEBIAN_FRONTEND=noninteractive


#
# make sure the package index cache is up-to-date before installing anything.

apt-get update


#
# expand the root partition.

apt-get install -y --no-install-recommends parted
partition_device="$(findmnt -no SOURCE /)"
partition_number="$(echo "$partition_device" | perl -ne '/(\d+)$/ && print $1')"
disk_device="$(echo "$partition_device" | perl -ne '/(.+?)\d+$/ && print $1')"
parted ---pretend-input-tty "$disk_device" <<EOF
resizepart $partition_number 100%
yes
EOF
resize2fs "$partition_device"


#
# install vim.

apt-get install -y --no-install-recommends vim

cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF


#
# configure the shell.

cat >/etc/profile.d/login.sh <<'EOF'
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF


#
# install tools.

apt-get install -y git-core
apt-get install -y jq
