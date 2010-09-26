
#ifndef TINYTDS_RESULT_H
#define TINYTDS_RESULT_H

void init_tinytds_result();

typedef struct {
  VALUE fields;
  VALUE rows;
  VALUE encoding;
  long numberOfFields;
  unsigned long numberOfRows;
  unsigned long lastRowProcessed;
  short int resultFreed;
  // MYSQL_RES *result;
} tinytds_result_wrapper;



#endif
