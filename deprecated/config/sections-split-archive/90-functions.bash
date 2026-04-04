# Section: shell functions (bash/zsh compatible usage)
run_n_times() {
  local n=$1 i=1; shift
  while [ "$i" -le "$n" ]; do
    "$@"
    i=$((i+1))
  done
}

run_multi_thread() {
  local thread_num=10 run_times=100
  local cmd=("$@")
  mkfifo tm1 2>/dev/null || return 1
  exec 5<>tm1
  rm -f tm1
  for ((i=1;i<=thread_num;i++)); do echo >&5; done
  for ((j=1;j<=run_times;j++)); do
    read -u5
    { "${cmd[@]}"; sleep 1; echo >&5; }&
  done
  wait
  exec 5>&-
  exec 5<&-
}
