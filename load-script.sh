#!/bin/sh
PGPASSWORD=root
PSQL='/usr/local/pgpro/bin/psql --set ON_ERROR_STOP=1 -1 -X -p 5434 -U postgres -h localhost advs'
$PSQL  < $1 && touch `basename $1 .sql`.mark
