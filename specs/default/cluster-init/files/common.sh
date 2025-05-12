#!/bin/bash
# Library of functions to be used across scripts
JETPACK=/opt/cycle/jetpack/bin/jetpack

read_os()
{
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
    os_version=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | xargs)
}

function is_slurm() {
    [ $($JETPACK config slurm.role not-slurm) != not-slurm ]
}

function is_pbs() {
    [ $($JETPACK config pbspro.version not-pbs) != not-pbs ]
}

function is_scheduler() {
    (is_slurm && $JETPACK config slurm.role | grep -q 'scheduler') || \
    (is_pbs && $JETPACK config roles | grep -q pbspro_server_role)
}

function is_login() {
    (is_slurm && $JETPACK config slurm.role | grep -q 'login') || \
    (is_pbs && $JETPACK config roles | grep -q pbspro_login_role)
}

function is_compute() {
    (is_slurm && $JETPACK config slurm.role | grep -q 'execute') || \
    (is_pbs && $JETPACK config roles | grep -q pbspro_execute_role)
}
