#include <tiny_tds_ext.h>
#include <client.h>
#include <errno.h>

VALUE cTinyTdsClient;
extern VALUE mTinyTds, cTinyTdsError;


static VALUE rb_tinytds_client_test(VALUE self) {
  return Qtrue;
}

void init_tinytds_client() {
  cTinyTdsClient = rb_define_class_under(mTinyTds, "Client", rb_cObject);
  rb_define_method(cTinyTdsClient, "test", rb_tinytds_client_test, 0);
}
