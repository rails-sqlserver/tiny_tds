
#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

typedef struct {
  short int closed;
  short int timing_out;
  short int dbsql_sent;
  short int dbsqlok_sent;
  RETCODE dbsqlok_retcode;
  short int dbcancel_sent;
} tinytds_client_userdata;

typedef struct {
  LOGINREC *login;
  RETCODE return_code;
  DBPROCESS *client;
  short int closed;
  VALUE charset;
  tinytds_client_userdata *userdata;
  #ifdef HAVE_RUBY_ENCODING_H
    rb_encoding *encoding;
  #endif
} tinytds_client_wrapper;


// Lib Macros

#define GET_CLIENT_USERDATA(dbproc) \
  tinytds_client_userdata *userdata = (tinytds_client_userdata *)dbgetuserdata(dbproc);


#endif
