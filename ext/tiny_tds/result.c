
#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;
VALUE cBigDecimal, cDate, cDateTime;
VALUE opt_decimal_zero, opt_float_zero, opt_time_year, opt_time_month, opt_utc_offset;
static ID intern_new, intern_utc, intern_local, intern_encoding_from_charset_code, intern_localtime, intern_merge, intern_local_offset, intern_civil, intern_new_offset;
static ID sym_symbolize_keys, sym_as, sym_array, sym_database_timezone, sym_application_timezone, sym_local, sym_utc;


void init_tinytds_result() {
  /* Data Classes */
  cBigDecimal = rb_const_get(rb_cObject, rb_intern("BigDecimal"));
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));
  cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
  /* Define TinyTds::Result */
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  /* Define TinyTds::Result Public Methods */
  // ...
  /* Intern String Helpers */
  intern_encoding_from_charset_code = rb_intern("encoding_from_charset_code");
  intern_new = rb_intern("new");
  intern_utc = rb_intern("utc");
  intern_local = rb_intern("local");
  intern_merge = rb_intern("merge");
  intern_localtime = rb_intern("localtime");
  intern_local_offset = rb_intern("local_offset");
  intern_civil = rb_intern("civil");
  intern_new_offset = rb_intern("new_offset");
  /* Symbol Helpers */
  sym_symbolize_keys = ID2SYM(rb_intern("symbolize_keys"));
  sym_as = ID2SYM(rb_intern("as"));
  sym_array = ID2SYM(rb_intern("array"));
  sym_local = ID2SYM(rb_intern("local"));
  sym_utc = ID2SYM(rb_intern("utc"));
  sym_database_timezone = ID2SYM(rb_intern("database_timezone"));
  sym_application_timezone = ID2SYM(rb_intern("application_timezone"));
  /* Data Conversion Options */
  opt_decimal_zero = rb_str_new2("0.0");
  rb_global_variable(&opt_decimal_zero);
  opt_float_zero = rb_float_new((double)0);
  rb_global_variable(&opt_float_zero);
  opt_time_year = INT2NUM(2000);
  opt_time_month = INT2NUM(1);
  opt_utc_offset = INT2NUM(0);
}
