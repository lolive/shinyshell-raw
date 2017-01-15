export BD=$(dirname ${BASH_SOURCE[0]})
unset -f param_names 2>&1 1>/dev/null
function param_names () {
 FUNCTION_FULLPATH=${1}
 grep '^\s*name_params' $FUNCTION_FULLPATH  | sed -e 's/.*name_params *//'
}
unset -f call_function 2>&1 1>/dev/null
function call_function () {
  [ -f $1 ] && [ ! -L $1 ] || return;
  FUNCTION_FULLPATH="$1"
  FUNCTION_FILENAME=`basename "$FUNCTION_FULLPATH"`
  CURRENT="$FUNCTION_FILENAME"
  BDTMP=$BD/.tmp
  [[ -f ${BD}/.error ]] && rm ${BD}/.error
  local PARAMS=`param_names ${FUNCTION_FULLPATH}`
  
  cat > $BDTMP <<EOF1
  unset -f ${CURRENT} 2>&1 1>/dev/null
  function ${CURRENT} () {
EOF1
  if [[ -n $PARAMS ]]; then
  cat >> $BDTMP <<EOF2
  for param_name in ${PARAMS}; do
EOF2
  cat >> $BDTMP <<'EOF3'
   eval existing_param_value=\$$param_name
   if [ -z ${existing_param_value} ]; then  
    if [[ -z ${1} ]]; then
EOF3
  cat >> $BDTMP <<EOF4
     echo ${CURRENT}: Expected params \"${PARAMS}\" >&2
EOF4
  cat >> $BDTMP <<'EOF5'
     echo "Too few parameters. Cancelling..." >&2
     return
    fi
    eval "local ${param_name}="'"'"$1"'"'
    shift
   else
    echo ${param_name} is already set to "${existing_param_value}" >&2
   fi
  done
EOF5
  cat >> $BDTMP <<'EOF7'
  if [[ -n ${1} ]]; then
EOF7
  cat >> $BDTMP <<EOF8
     echo ${CURRENT}: Expected params \"${PARAMS}\" >&2
EOF8
  cat >> $BDTMP <<'EOF9'
     echo "Too many parameters. Cancelling..." >&2
     return
  fi
EOF9
  fi
  grep -v name_params $FUNCTION_FULLPATH >> $BDTMP
  cat >> $BDTMP <<'EOF'
  }
EOF
  source $BDTMP
}
for raw_function in $BD/.raw/*; do call_function ${raw_function}; done
for function_or_alias in $BD/*/*; do manage_function_or_alias ${function_or_alias}; done
