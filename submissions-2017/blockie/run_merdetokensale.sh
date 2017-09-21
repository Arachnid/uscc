#!/usr/bin/env bash
printf "=== Initializing TestRPC ===\n"
./node_modules/.bin/testrpc --gasLimit 999999999 &> testrpc.log &
_testrpc_pid="$!"
printf "\n=== Initializing tests ===\n"
node test_merdetokensale.javascript
printf "=== Tests finished ===\n"
kill "$_testrpc_pid"
printf "\n=== Bye bye bird ===\n"
