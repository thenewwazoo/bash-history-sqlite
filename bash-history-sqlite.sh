#!/bin/bash

HISTSESSION=`dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64`

# This utility requires bash-preexec to function, so get it.
# n.b. we presume cwd is ~
if [ ! -f ${HOME}/.bash-preexec.sh ]
then
    wget -q -O ${HOME}/.bash-preexec.sh 'https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh' 2> /dev/null ||
    curl -s -o ${HOME}/.bash-preexec.sh 'https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh' 2> /dev/null
fi
source ${HOME}/.bash-preexec.sh

# header guard
[ -n "$_SQLITE_HIST" ] && return || readonly _SQLITE_HIST=1


# Let's define some utility functions
# TODO figure out how to integrate this with the history builtins

dbhistory() {
    sqlite3 -separator '#' ${HISTDB} "select command_id, command from command where command like '%${@}%';" | awk -F'#' '/^[0-9]+#/ {printf "%8s    %s\n", $1, substr($0,index($0,FS)+1); next} { print $0; }'
}

dbhist() {
    dbhistory "$@"
}

# TODO figure out how to make this function rewrite history so the up arrow
#  (or ^r searches) give you what you ran, and not the dbexec() call.
dbexec() {
    bash -c "$(sqlite3 "${HISTDB}" "select command from command where command_id='${1}';")"
}


# The magic follows

__quote_str() {
	local str
	local quoted
	str="$1"
	quoted="'$(echo "$str" | sed -e "s/'/''/g")'"
	echo "$quoted"
}
__create_histdb() {
	if bash -c "set -o noclobber; > \"$HISTDB\" ;" &> /dev/null; then
		sqlite3 "$HISTDB" <<-EOD
		CREATE TABLE command (
			command_id INTEGER PRIMARY KEY,
			shell TEXT,
			command TEXT,
			cwd TEXT,
			return INTEGER,
			started INTEGER,
			ended INTEGER,
			shellsession TEXT,
			loginsession TEXT
		);
		EOD
	fi
}

preexec_bash_history_sqlite() {
	[[ -z ${HISTDB} ]] && return 0
	local cmd
	cmd="$1"

	#atomic create file if not exist
	__create_histdb

	local quotedloginsession
	if [[ -n "${LOGINSESSION}" ]]; then
		quotedloginsession=$(__quote_str "$LOGINSESSION")
	else
		quotedloginsession="NULL"
	fi
	LASTHISTID="$(sqlite3 "$HISTDB" <<-EOD
		INSERT INTO command (shell, command, cwd, started, shellsession, loginsession)
		VALUES (
			'bash',
			$(__quote_str "$cmd"),
			$(__quote_str "$PWD"),
			'$(date +%s%3N)',
			$(__quote_str "$HISTSESSION"),
			$quotedloginsession
		);
		SELECT last_insert_rowid();
		EOD
	)"

	echo "$cmd" >> ~/.testlog
}

precmd_bash_history_sqlite() {
	local ret_value="$?"
	if [[ -n "${LASTHISTID}" ]]; then
		__create_histdb
		sqlite3 "$HISTDB" <<- EOD
			UPDATE command SET
				ended='$(date +%s%3N)',
				return=$ret_value
			WHERE
				command_id=$LASTHISTID ;
		EOD
	fi
}

preexec_functions+=(preexec_bash_history_sqlite)
precmd_functions+=(precmd_bash_history_sqlite)
