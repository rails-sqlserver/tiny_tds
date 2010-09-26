
#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

typedef struct {
  LOGINREC *login;
  RETCODE return_code;
  DBPROCESS *client;
  short int closed;
} tinytds_client_wrapper;


#endif
