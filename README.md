
The Internet never forgets... your bash history
===============================================
(also, this isn't on the Internet)

This is a bash script based on one written by [HN user leni536](https://news.ycombinator.com/item?id=10163972) that stores your bash command history (and metadata) in an sqlite3 database. This script is only tested to work on OS X El Cap.

Installation
------------

Check out the repo, and add the contents of `bash-profile.stub` to the end of your `~/.bash_profile`. Place the `bash-history-sqlite.sh` script in your `$HOME` with filename `.bash-history-sqlite.sh`.

Use
---

The `history` bash builtin still only reads `~/.bash_history`, so your `!` commands (and other such tools) don't know anything about the sqlite3 db. There are three utility functions defined:
* `dbhistory`: Search the sqlite3 db using a `LIKE` SQL query.
* `dbhist`: alias for `dbhistory`
* `dbexec`: Execute the historical command_id specified
