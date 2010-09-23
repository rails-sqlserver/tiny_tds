#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;



void init_tinytds_result() {
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  
}
