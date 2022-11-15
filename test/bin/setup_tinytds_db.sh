#!/usr/bin/env bash

set -x
set -e

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i ./test/sql/db-create.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i ./test/sql/db-login.sql
