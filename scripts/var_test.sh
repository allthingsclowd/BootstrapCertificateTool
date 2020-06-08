#!/usr/bin/env bash

unset Lemons_ssh

echo "Testing if Lemons is unset: ${Lemons_ssh}"

[ -z "${Lemons_ssh}" ] && echo "UNSET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >" || echo "SET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >"

prefix=Lemons

eval "${prefix}"_ssh=Whoopie

echo "Testing if Lemons is set: ${Lemons_ssh}"

[ -z "${Lemons_ssh}" ] && echo "UNSET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >" || echo "SET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >"

Lemons_ssh="Whoopie"

echo "Testing if Lemons is set: ${Lemons_ssh}"

[ -z "${Lemons_ssh}" ] && echo "UNSET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >" || echo "SET: Variable '${Lemons_ssh}' contains < ${Lemons_ssh} >"

