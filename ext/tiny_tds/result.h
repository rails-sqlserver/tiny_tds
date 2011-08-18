
#ifndef TINYTDS_RESULT_H
#define TINYTDS_RESULT_H

#ifndef DBSETLDBNAME
  typedef tds_sysdep_int64_type DBBIGINT;  /* For FreeTDS 0.82 */
#endif

void init_tinytds_result();
VALUE rb_tinytds_new_result_obj(DBPROCESS *c);

typedef struct {
  DBPROCESS *client;
  VALUE local_offset;
  VALUE fields;
  VALUE fields_processed;
  VALUE results;
  #ifdef HAVE_RUBY_ENCODING_H
    rb_encoding *encoding;
  #endif
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
