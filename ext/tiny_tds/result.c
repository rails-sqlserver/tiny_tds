#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;


static VALUE rb_tinytds_result_test(VALUE self) {
  return Qtrue;
}

void init_tinytds_result() {
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  rb_define_method(cTinyTdsClient, "test", rb_tinytds_result_test, 0);
}
