#include <tiny_tds_ext.h>

void nogvl_setup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 1;
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors = malloc(ERRORS_STACK_INIT_SIZE * sizeof(tinytds_errordata));
  userdata->nonblocking_errors_size = ERRORS_STACK_INIT_SIZE;
}

void nogvl_cleanup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 0;
  userdata->timing_out = 0;
  /*
  Now that the blocking operation is done, we can finally throw any
  exceptions based on errors from SQL Server.
  */
  short int i;

  for (i = 0; i < userdata->nonblocking_errors_length; i++) {
    tinytds_errordata error = userdata->nonblocking_errors[i];

    // lookahead to drain any info messages ahead of raising error
    if (!error.is_message) {
      short int j;

      for (j = i; j < userdata->nonblocking_errors_length; j++) {
        tinytds_errordata msg_error = userdata->nonblocking_errors[j];

        if (msg_error.is_message) {
          rb_tinytds_raise_error(client, msg_error);
        }
      }
    }

    rb_tinytds_raise_error(client, error);
  }

  free(userdata->nonblocking_errors);
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors_size = 0;
}

void dbcancel_ubf(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  dbcancel(client);
  userdata->dbcancel_sent = 1;
}

// No GVL Helpers
RETCODE nogvl_dbsqlexec(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlexec, client);
  nogvl_cleanup(client);
  return retcode;
}

RETCODE nogvl_dbsqlok(DBPROCESS *client)
{
  int retcode = FAIL;
  GET_CLIENT_USERDATA(client);
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlok, client);
  nogvl_cleanup(client);
  userdata->dbsqlok_sent = 1;
  return retcode;
}

RETCODE nogvl_dbresults(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbresults, client);
  nogvl_cleanup(client);
  return retcode;
}

RETCODE nogvl_dbnextrow(DBPROCESS * client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbnextrow, client);
  nogvl_cleanup(client);
  return retcode;
}
