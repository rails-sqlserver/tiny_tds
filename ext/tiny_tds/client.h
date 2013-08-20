
#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

typedef struct {
  short int is_set;
  int cancel;
  char error[1024];
  char source[1024];
  int severity;
  int dberr;
  int oserr;
} tinytds_errordata;

typedef struct {
  short int closed;
  short int timing_out;
  short int dbsql_sent;
  short int dbsqlok_sent;
  RETCODE dbsqlok_retcode;
  short int dbcancel_sent;
  short int nonblocking;
  tinytds_errordata nonblocking_error;
} tinytds_client_userdata;

typedef struct {
  LOGINREC *login;
  RETCODE return_code;
  DBPROCESS *client;
  short int closed;
  VALUE charset;
  tinytds_client_userdata *userdata;
  const char *identity_insert_sql;
  rb_encoding *encoding;
} tinytds_client_wrapper;


// Lib Macros

#define GET_CLIENT_USERDATA(dbproc) \
  tinytds_client_userdata *userdata = (tinytds_client_userdata *)dbgetuserdata(dbproc);


#endif
