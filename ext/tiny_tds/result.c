
#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;
VALUE cBigDecimal, cDate, cDateTime, cRational;
VALUE opt_decimal_zero, opt_float_zero, opt_one, opt_zero, opt_four, opt_19hdr, opt_tenk, opt_onemil;
static ID intern_new, intern_utc, intern_local, intern_localtime, intern_merge, 
          intern_local_offset, intern_civil, intern_new_offset, intern_plus, intern_divide;
static ID sym_symbolize_keys, sym_as, sym_array, sym_database_timezone, sym_application_timezone, sym_local, sym_utc;

#ifdef HAVE_RUBY_ENCODING_H
  rb_encoding *binaryEncoding;
  #define ENCODED_STR_NEW(_data, _len) ({ \
    VALUE _val = rb_str_new((char *)_data, (long)_len); \
    rb_enc_associate(_val, rwrap->encoding); \
    _val; \
  })
  #define ENCODED_STR_NEW2(_data2) ({ \
    VALUE _val = rb_str_new2((char *)_data2); \
    rb_enc_associate(_val, rwrap->encoding); \
    _val; \
  })
#else
  #define ENCODED_STR_NEW(_data, _len) \
    rb_str_new((char *)_data, (long)_len);
  #define ENCODED_STR_NEW2(_data2) \
    rb_str_new2((char *)_data2);
#endif


// Lib Backend (Memory Management)

static void rb_tinytds_result_mark(void *ptr) {
  tinytds_result_wrapper *rwrap = (tinytds_result_wrapper *)ptr;
  if (rwrap) {
    rb_gc_mark(rwrap->fields);
    rb_gc_mark(rwrap->rows);
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
    int col = i+1;
    int coltype = dbcoltype(rwrap->client, col);
    BYTE *data = dbdata(rwrap->client, col);
    DBINT data_len = dbdatlen(rwrap->client, col);
    int null_val = ((data == NULL) && (data_len == 0));
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
          val = INT2NUM(*(long *)data);
          break;
        case SYBBIT:
          val = *(int *)data ? Qtrue : Qfalse;
          break;
        case SYBNUMERIC:
        case SYBDECIMAL: { 
          DBTYPEINFO *data_info = dbcoltypeinfo(rwrap->client, col);
          int data_slength = (int)data_info->precision + (int)data_info->scale + 1;
          char converted_decimal[data_slength];
          dbconvert(rwrap->client, coltype, data, data_len, SYBVARCHAR, (BYTE *)converted_decimal, -1);
          val = rb_funcall(cBigDecimal, intern_new, 1, rb_str_new2((char *)converted_decimal));
          break;
        }
        case SYBFLT8: {
          double col_to_double = *(double *)data;
          val = (col_to_double == 0.000000) ? opt_float_zero : rb_float_new(col_to_double);
          break;
        }
        case SYBREAL: {
          float col_to_float = *(float *)data;
          val = (col_to_float == 0.0) ? opt_float_zero : rb_float_new(col_to_float);
          break;
        }
        case SYBMONEY: {
          DBMONEY *money = (DBMONEY *)data;
          char converted_money[25];
          long money_value = ((long)money->mnyhigh << 32) | money->mnylow;
          sprintf(converted_money, "%ld", money_value);
          val = rb_funcall(cBigDecimal, intern_new, 2, rb_str_new2(converted_money), opt_four);
          val = rb_funcall(val, intern_divide, 1, opt_tenk);
          break;
        }
        case SYBMONEY4: {
          DBMONEY4 *money = (DBMONEY4 *)data;
          char converted_money[20];
          sprintf(converted_money, "%f", money->mny4 / 10000.0);
          val = rb_funcall(cBigDecimal, intern_new, 1, rb_str_new2(converted_money));
          break;
        }
        case SYBBINARY:
        case SYBIMAGE:
          val = rb_str_new((char *)data, (long)data_len);
          #ifdef HAVE_RUBY_ENCODING_H
            rb_enc_associate(val, binaryEncoding);
          #endif
          break;
        case 36: { // SYBUNIQUE
          char converted_unique[32];
          dbconvert(rwrap->client, coltype, data, 32, SYBVARCHAR, (BYTE *)converted_unique, -1);
          val = ENCODED_STR_NEW2(converted_unique);
          break;
        } 
        case SYBDATETIME: {
          DBDATEREC date_rec;
          dbdatecrack(rwrap->client, &date_rec, (DBDATETIME*)data);
          int year  = date_rec.year,
              month = date_rec.month,
              day   = date_rec.day,
              hour  = date_rec.hour,
              min   = date_rec.minute,
              sec   = date_rec.second,
              msec  = date_rec.millisecond;
          if (year+month+day+hour+min+sec+msec == 0) {
            val = Qnil;
          } else {
            if (month < 1 || day < 1) {
              rb_raise(cTinyTdsError, "Invalid date");
              val = Qnil;
            } else {
              /* Use DateTime */
              if (year < 1902 || year+month+day > 2058) {
                VALUE offset = opt_zero;
                if (db_timezone == intern_local) {
                  offset = rb_funcall(cTinyTdsClient, intern_local_offset, 0);
                }
                VALUE datetime_sec = INT2NUM(sec);
                if (msec != 0) {
                  VALUE rational_msec = rb_funcall(cRational, intern_new, 2, INT2NUM(msec*1000), opt_onemil);
                  datetime_sec = rb_funcall(datetime_sec, intern_plus, 1, rational_msec);                  
                }
                val = rb_funcall(cDateTime, intern_civil, 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), datetime_sec, offset);
                if (!NIL_P(app_timezone)) {
                  if (app_timezone == intern_local) {
                    offset = rb_funcall(cTinyTdsClient, intern_local_offset, 0);
                    val = rb_funcall(val, intern_new_offset, 1, offset);
                  } else { // utc
                    val = rb_funcall(val, intern_new_offset, 1, opt_zero);
                  }
                }
              /* Use Time */
              } else {
                val = rb_funcall(rb_cTime, db_timezone, 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(msec*1000));
                if (!NIL_P(app_timezone)) {
                  if (app_timezone == intern_local) {
                    val = rb_funcall(val, intern_localtime, 0);
                  } else { // utc
                    val = rb_funcall(val, intern_utc, 0);
                  }
                }
              }
            }
          }
          break;
        }
        case SYBDATETIME4: {
          DBDATETIME4 *date = (DBDATETIME4 *)data;
          DBUSMALLINT days_since_1900 = date->days, minutes = date->minutes;
          val = rb_funcall(rb_cTime, db_timezone, 6, opt_19hdr, opt_one, opt_one, opt_zero, opt_zero, opt_zero);
          unsigned long int seconds_since_1900 = ((long)days_since_1900 * 24 * 3600) + ((long)minutes * 60);
          val = rb_funcall(val, intern_plus, 1, INT2NUM(seconds_since_1900));
          break;
        }
        case SYBCHAR:
        case SYBTEXT:
          val = ENCODED_STR_NEW(data, data_len);
          break;
        default:
          val = ENCODED_STR_NEW(data, data_len);
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
  defaults = rb_iv_get(self, "@query_options");
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
        // TODO: Account for failed dbresults() must have returned FAIL.
        rb_warn("TinyTds: dbresults() must have returned FAIL.\n");
      }
    }
    if (return_code == FAIL) {
      // TODO: Account for something in the dbresults() while loop set the return code to FAIL.
      rb_warn("TinyTds: Something in the dbresults() while loop set the return code to FAIL.\n");
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
  cRational = rb_const_get(rb_cObject, rb_intern("Rational"));
  /* Define TinyTds::Result */
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  /* Define TinyTds::Result Public Methods */
  rb_define_method(cTinyTdsResult, "each", rb_tinytds_result_each, -1);
  rb_define_method(cTinyTdsResult, "fields", rb_tinytds_result_fields, 0);
  rb_define_method(cTinyTdsResult, "cancel", rb_tinytds_result_cancel, 0);
  /* Intern String Helpers */
  intern_new = rb_intern("new");
  intern_utc = rb_intern("utc");
  intern_local = rb_intern("local");
  intern_merge = rb_intern("merge");
  intern_localtime = rb_intern("localtime");
  intern_local_offset = rb_intern("local_offset");
  intern_civil = rb_intern("civil");
  intern_new_offset = rb_intern("new_offset");
  intern_plus = rb_intern("+");
  intern_divide = rb_intern("/");
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
  opt_one = INT2NUM(1);
  opt_zero = INT2NUM(0);
  opt_four = INT2NUM(4);
  opt_19hdr = INT2NUM(1900);
  opt_tenk = INT2NUM(10000);
  opt_onemil = INT2NUM(1000000);
  /* Encoding */
  #ifdef HAVE_RUBY_ENCODING_H
    binaryEncoding = rb_enc_find("binary");
  #endif
}
