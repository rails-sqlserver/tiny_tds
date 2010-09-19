#include <ruby.h>
#include "tiny_tds.h"

void Init_tiny_tds() {
  VALUE rb_mTinyTds = rb_define_module("TinyTds");
  rb_define_method(rb_mTinyTds, "connect", connect, 0);
}

static void connect() {
  
}
