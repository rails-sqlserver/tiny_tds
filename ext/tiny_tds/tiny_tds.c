#include <ruby.h>
#include "tiny_tds.h"

void Init_tiny_tds() {
  VALUE rb_mTinyTDS = rb_define_module("TinyTDS");
  rb_define_method(rb_mTinyTDS, "connect", connect, 0);
}

static void connect() {
  
}
