
#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;
VALUE cBigDecimal, cDate, cDateTime;
VALUE opt_decimal_zero, opt_float_zero, opt_time_year, opt_time_month, opt_utc_offset;
static ID intern_new, intern_utc, intern_local, intern_encoding_from_charset_code, intern_localtime, intern_merge, intern_local_offset, intern_civil, intern_new_offset;
static ID sym_symbolize_keys, sym_as, sym_array, sym_database_timezone, sym_application_timezone, sym_local, sym_utc;



// Lib Backend (Memory Management)

static void rb_tinytds_result_mark(void *ptr) {
  tinytds_result_wrapper *rwrap = (tinytds_result_wrapper *)ptr;
  if (rwrap) {
    rb_gc_mark(rwrap->fields);
    rb_gc_mark(rwrap->rows);
    rb_gc_mark(rwrap->encoding);
  }
}

static void rb_tinytds_result_free(void *ptr) {
  tinytds_result_wrapper *rwrap = (tinytds_result_wrapper *)ptr;
  xfree(ptr);
}

VALUE rb_tinytds_new_result_obj(DBPROCESS *c) {
  VALUE obj;
  tinytds_result_wrapper *rwrap;
  obj = Data_Make_Struct(cTinyTdsResult, tinytds_result_wrapper, rb_tinytds_result_mark, rb_tinytds_result_free, rwrap);
  rwrap->client = c;
  rwrap->return_code = 0;
  rwrap->fields = Qnil;
  rwrap->rows = Qnil;
  rwrap->encoding = Qnil;
  rwrap->number_of_fields = 0;
  rwrap->number_of_rows = 0;
  rb_obj_call_init(obj, 0, NULL);
  return obj;
}


// Lib Backend (Helpers)

static VALUE rb_tinytds_result_fetch_row(VALUE self, ID db_timezone, ID app_timezone, int symbolize_keys, int as_array) {
  /* Wrapper And Local Vars */
  GET_RESULT_WRAPPER(self);
  VALUE row;
  unsigned int i = 0;
  /* One-Time Fields Info & Container */
  if (NIL_P(rwrap->fields)) {
    rwrap->number_of_fields = dbnumcols(rwrap->client);
    rwrap->fields = rb_ary_new2(rwrap->number_of_fields);
    for (i = 0; i < rwrap->number_of_fields; i++) {
      char *colname = dbcolname(rwrap->client, i+1);
      VALUE field = symbolize_keys ? ID2SYM(rb_intern(colname)) : rb_str_new2(colname);
      rb_ary_store(rwrap->fields, i, field);
    }
  }
  /* Create Empty Row */
  if (as_array) {
    row = rb_ary_new2(rwrap->number_of_fields);
  } else {
    row = rb_hash_new();
  }
  /* Storing Values */
  for (i = 0; i < rwrap->number_of_fields; i++) {
    VALUE val = Qnil;
    BYTE *data = dbdata(rwrap->client, i+1);
    int coltype = dbcoltype(rwrap->client, i+1);
    int null_val = dbdatlen(rwrap->client, i+1) == 0;
    if (!null_val) {
      switch(coltype) {
        case SYBINT1:
          val = INT2FIX(*(DBTINYINT *)data);
          break;
        case SYBINT2:
          val = INT2FIX(*(DBSMALLINT *)data);
          break;
        case SYBINT4:
          val = INT2NUM(*(DBINT *)data);
          break;
        case SYBINT8:
          val = INT2NUM(*(DBINT *)data);
          break;
        default:
          val = rb_str_new2(data);
          break;
      }
    }
    if (as_array) {
      rb_ary_store(row, i, val);
    } else {
      rb_hash_aset(row, rb_ary_entry(rwrap->fields, i), val);
    }
  }
  return row;
}


// TinyTds::Client (public)

static VALUE rb_tinytds_result_each(int argc, VALUE * argv, VALUE self) {
  GET_RESULT_WRAPPER(self);
  /* Local Vars */
  VALUE defaults, opts, block;
  ID opt_db_tz, opt_app_tz, db_timezone, app_timezone;
  int symbolize_keys = 0, as_array = 0, cache_rows = 1;
  /* Merge Options Hash, Populate Opts & Block Var */
  defaults = rb_iv_get(self, "@query_options"); // TODO: intern these string?
  if (rb_scan_args(argc, argv, "01&", &opts, &block) == 1) {
    opts = rb_funcall(defaults, intern_merge, 1, opts);
  } else {
    opts = defaults;
  }
  /* Locals From Options */
  if (rb_hash_aref(opts, sym_symbolize_keys) == Qtrue)
    symbolize_keys = 1;
  if (rb_hash_aref(opts, sym_as) == sym_array)
    as_array = 1;
  /* Locals From Options (:database_timezone) */
  opt_db_tz = rb_hash_aref(opts, sym_database_timezone);
  if (opt_db_tz == sym_local) {
    db_timezone = intern_local;
  } else if (opt_db_tz == sym_utc) {
    db_timezone = intern_utc;
  } else {
    if (!NIL_P(opt_db_tz))
      rb_warn(":database_timezone option must be :utc or :local - defaulting to :local");
    db_timezone = intern_local;
  }
  /* Locals From Options (:application_timezone) */
  opt_app_tz = rb_hash_aref(opts, sym_application_timezone);
  if (opt_app_tz == sym_local) {
    app_timezone = intern_local;
  } else if (opt_app_tz == sym_utc) {
    app_timezone = intern_utc;
  } else {
    app_timezone = Qnil;
  }
  /* Make The Rows Or Yield Existing */
  if (NIL_P(rwrap->rows)) {
    rwrap->rows = rb_ary_new();
    RETCODE return_code;
    while ((return_code = dbresults(rwrap->client)) != NO_MORE_RESULTS) { 
      if (return_code == SUCCEED) {
        /* If no actual rows, return the empty array. */
        if (DBROWS(rwrap->client) != SUCCEED)
          return rwrap->rows;
        unsigned long rowi = 0;
        while (dbnextrow(rwrap->client) != NO_MORE_ROWS) {
          VALUE row = rb_tinytds_result_fetch_row(self, db_timezone, app_timezone, symbolize_keys, as_array);
          rb_ary_store(rwrap->rows, rowi, row);
          if (!NIL_P(block))
            rb_yield(row);
          rowi++;
        }
        rwrap->number_of_rows = rowi;
      } else {
        // Failed dbresults() function? Raise hell?
      }
    }
  } else if (!NIL_P(block)) {
    unsigned long i;
    for (i = 0; i < rwrap->number_of_rows; i++) {
      rb_yield(rb_ary_entry(rwrap->rows, i));
    }
  }
  return rwrap->rows;
}

static VALUE rb_tinytds_result_fields(VALUE self) {
  GET_RESULT_WRAPPER(self);
  return rwrap->fields;
}

static VALUE rb_tinytds_result_cancel(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client)
    dbcancel(rwrap->client);
  return Qtrue;
}


// Lib Init

void init_tinytds_result() {
  /* Data Classes */
  cBigDecimal = rb_const_get(rb_cObject, rb_intern("BigDecimal"));
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));
  cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
  /* Define TinyTds::Result */
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  /* Define TinyTds::Result Public Methods */
  rb_define_method(cTinyTdsResult, "each", rb_tinytds_result_each, -1);
  rb_define_method(cTinyTdsResult, "fields", rb_tinytds_result_fields, 0);
  rb_define_method(cTinyTdsResult, "cancel", rb_tinytds_result_cancel, 0);
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
