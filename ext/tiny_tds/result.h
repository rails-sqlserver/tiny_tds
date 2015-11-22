
#ifndef TINYTDS_RESULT_H
#define TINYTDS_RESULT_H

void init_tinytds_result();
VALUE rb_tinytds_new_result_obj(tinytds_client_wrapper *cwrap);

typedef struct {
  tinytds_client_wrapper *cwrap;
  DBPROCESS *client;
  VALUE local_offset;
  VALUE fields;
  VALUE fields_processed;
  VALUE results;
  rb_encoding *encoding;
  VALUE dbresults_retcodes;
  unsigned int number_of_results;
  unsigned int number_of_fields;
  unsigned long number_of_rows;
} tinytds_result_wrapper;


// Lib Macros

#define GET_RESULT_WRAPPER(self) \
  tinytds_result_wrapper *rwrap; \
  Data_Get_Struct(self, tinytds_result_wrapper, rwrap)




#endif
