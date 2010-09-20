#ifndef TINYTDS_RESULT_H
#define TINYTDS_RESULT_H

void init_tinytds_result();
// VALUE rb_tinytds_result_to_obj(MYSQL_RES * r);

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
