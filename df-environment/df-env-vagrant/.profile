# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

export HADOOP_CONF_DIR="/mnt/etc/hadoop"
export HADOOP_LOG_DIR="/mnt/logs"
export HIVE_CONF_DIR="/mnt/etc/hive"
export HADOOP_USER_CLASSPATH_FIRST=true
export JAVA_HOME="/opt/jdk"

PATH="/opt/hadoop/bin:$PATH"
PATH="/opt/hadoop/sbin:$PATH"
PATH="/opt/confluent/bin:$PATH"
PATH="/opt/hive/bin:$PATH"
