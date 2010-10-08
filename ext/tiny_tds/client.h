
#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

typedef struct {
  LOGINREC *login;
  RETCODE return_code;
  DBPROCESS *client;
  short int closed;
  VALUE charset;
  #ifdef HAVE_RUBY_ENCODING_H
    rb_encoding *encoding;
  #endif
} tinytds_client_wrapper;


#endif
