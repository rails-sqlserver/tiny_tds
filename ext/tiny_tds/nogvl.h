#ifndef TINYTDS_NOGVL_H
#define TINYTDS_NOGVL_H

#define NOGVL_DBCALL(_dbfunction, _client) ( \
  (RETCODE)(intptr_t)rb_thread_call_without_gvl( \
    (void *(*)(void *))_dbfunction, _client, \
    (rb_unblock_function_t*)dbcancel_ubf, _client ) \
)

void dbcancel_ubf(DBPROCESS *client);
RETCODE nogvl_dbnextrow(DBPROCESS * client);
RETCODE nogvl_dbresults(DBPROCESS *client);
RETCODE nogvl_dbsqlexec(DBPROCESS *client);
RETCODE nogvl_dbsqlok(DBPROCESS *client);

#endif