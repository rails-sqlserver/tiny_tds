
#ifndef TINYTDS_RESULT_H
#define TINYTDS_RESULT_H

void init_tinytds_result();
VALUE rb_tinytds_new_result_obj(DBPROCESS *c);

typedef struct {
  DBPROCESS *client;
  RETCODE return_code;
  VALUE fields;
  VALUE rows;
  VALUE encoding;
  long number_of_fields;
  unsigned long number_of_rows;
} tinytds_result_wrapper;


#define GET_RESULT_WRAPPER(self) \
  tinytds_result_wrapper *rwrap; \
  Data_Get_Struct(self, tinytds_result_wrapper, rwrap)




#endif
