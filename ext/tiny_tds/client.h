#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

typedef struct {
  VALUE encoding;
  short int active;
  short int closed;
  DBPROCESS *client;
} tinytds_client_wrapper;


#endif
