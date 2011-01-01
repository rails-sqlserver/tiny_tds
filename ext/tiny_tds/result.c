
#include <tiny_tds_ext.h>

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;
VALUE cBigDecimal, cDate, cDateTime;
VALUE opt_decimal_zero, opt_float_zero, opt_one, opt_zero, opt_four, opt_19hdr, opt_tenk, opt_onemil;
int   opt_ruby_186;
static ID intern_new, intern_utc, intern_local, intern_localtime, intern_merge, 
          intern_civil, intern_new_offset, intern_plus, intern_divide, intern_Rational;
static ID sym_symbolize_keys, sym_as, sym_array, sym_cache_rows, sym_first, sym_timezone, sym_local, sym_utc;

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
    rb_str_new((char *)_data, (long)_len)
  #define ENCODED_STR_NEW2(_data2) \
    rb_str_new2((char *)_data2)
#endif


// Lib Backend (Memory Management)

static void rb_tinytds_result_mark(void *ptr) {
  tinytds_result_wrapper *rwrap = (tinytds_result_wrapper *)ptr;
  if (rwrap) {
    rb_gc_mark(rwrap->local_offset);
    rb_gc_mark(rwrap->fields);
    rb_gc_mark(rwrap->results);
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
  rwrap->local_offset = Qnil;
  rwrap->fields = Qnil;
  rwrap->results = Qnil;
  rwrap->number_of_results = 0;
  rwrap->number_of_fields = 0;
  rwrap->number_of_rows = 0;
  rb_obj_call_init(obj, 0, NULL);
  return obj;
}


// Lib Backend (Helpers)

static VALUE rb_tinytds_result_fetch_row(VALUE self, ID timezone, int symbolize_keys, int as_array) {
  /* Wrapper And Local Vars */
  GET_RESULT_WRAPPER(self);
  /* Create Empty Row */
  VALUE row = as_array ? rb_ary_new2(rwrap->number_of_fields) : rb_hash_new();
  /* Storing Values */
  unsigned int i = 0;
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
          val = LL2NUM(*(DBBIGINT *)data);
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
          long long money_value = ((long long)money->mnyhigh << 32) | money->mnylow;
          sprintf(converted_money, "%lld", money_value);
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
          char converted_unique[37];
          dbconvert(rwrap->client, coltype, data, 37, SYBVARCHAR, (BYTE *)converted_unique, -1);
          val = ENCODED_STR_NEW2(converted_unique);
          break;
        }
        case SYBDATETIME4: {
          DBDATETIME new_data;
          dbconvert(rwrap->client, coltype, data, data_len, SYBDATETIME, (BYTE *)&new_data, sizeof(new_data));
          data = (BYTE *)&new_data;
          data_len = sizeof(new_data);
        }
        case SYBDATETIME: {
          DBDATEREC date_rec;
          dbdatecrack(rwrap->client, &date_rec, (DBDATETIME *)data);
          int year  = date_rec.year,
              month = date_rec.month,
              day   = date_rec.day,
              hour  = date_rec.hour,
              min   = date_rec.minute,
              sec   = date_rec.second,
              msec  = date_rec.millisecond;
          if (year+month+day+hour+min+sec+msec != 0) {
            VALUE offset = (timezone == intern_local) ? rwrap->local_offset : opt_zero;
            /* Use DateTime */
            if (year < 1902 || year+month+day > 2058) {
              VALUE datetime_sec = INT2NUM(sec);
              if (msec != 0) {
                if ((opt_ruby_186 == 1 && sec < 59) || (opt_ruby_186 != 1)) {
                  #ifdef HAVE_RUBY_ENCODING_H
                    VALUE rational_msec = rb_Rational2(INT2NUM(msec*1000), opt_onemil);
                  #else
                    VALUE rational_msec = rb_funcall(rb_cObject, intern_Rational, 2, INT2NUM(msec*1000), opt_onemil);
                  #endif
                  datetime_sec = rb_funcall(datetime_sec, intern_plus, 1, rational_msec);
                }
              }
              val = rb_funcall(cDateTime, intern_civil, 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), datetime_sec, offset);
              val = rb_funcall(val, intern_new_offset, 1, offset);
            /* Use Time */
            } else {
              val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(msec*1000));
            }
          }
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
      VALUE key;
      if (rwrap->number_of_results == 0) {
        key = rb_ary_entry(rwrap->fields, i);
      } else {
        key = rb_ary_entry(rb_ary_entry(rwrap->fields, rwrap->number_of_results), i);
      }
      rb_hash_aset(row, key, val);
    }
  }
  return row;
}


// TinyTds::Client (public)

static VALUE rb_tinytds_result_each(int argc, VALUE * argv, VALUE self) {
  GET_RESULT_WRAPPER(self);
  /* Local Vars */
  VALUE defaults, opts, block;
  ID timezone;
  int symbolize_keys = 0, as_array = 0, cache_rows = 0, first = 0;
  /* Merge Options Hash, Populate Opts & Block Var */
  defaults = rb_iv_get(self, "@query_options");
  if (rb_scan_args(argc, argv, "01&", &opts, &block) == 1) {
    opts = rb_funcall(defaults, intern_merge, 1, opts);
  } else {
    opts = defaults;
  }
  /* Locals From Options */
  if (rb_hash_aref(opts, sym_first) == Qtrue)
    first = 1;
  if (rb_hash_aref(opts, sym_symbolize_keys) == Qtrue)
    symbolize_keys = 1;
  if (rb_hash_aref(opts, sym_as) == sym_array)
    as_array = 1;
  if (rb_hash_aref(opts, sym_cache_rows) == Qtrue)
    cache_rows = 1;
  if (rb_hash_aref(opts, sym_timezone) == sym_local) {
    timezone = intern_local;
  } else if (rb_hash_aref(opts, sym_timezone) == sym_utc) {
    timezone = intern_utc;
  } else {
    rb_warn(":timezone option must be :utc or :local - defaulting to :local");
    timezone = intern_local;
  }
  /* Make The Results Or Yield Existing */
  if (NIL_P(rwrap->results)) {
    rwrap->results = rb_ary_new();
    RETCODE dbsqlok_rc = 0;
    RETCODE dbresults_rc = 0;
    dbsqlok_rc = dbsqlok(rwrap->client);
    dbresults_rc = dbresults(rwrap->client);
    while ((dbsqlok_rc == SUCCEED) && (dbresults_rc == SUCCEED)) {
      /* Only do field and row work if there are rows in this result set. */
      int has_rows = (DBROWS(rwrap->client) == SUCCEED) ? 1 : 0;
      int number_of_fields = has_rows ? dbnumcols(rwrap->client) : 0;
      if (has_rows && (number_of_fields > 0)) {
        /* Create fields for this result set. */
        unsigned int fldi = 0;
        rwrap->number_of_fields = number_of_fields;
        VALUE fields = rb_ary_new2(rwrap->number_of_fields);
        for (fldi = 0; fldi < rwrap->number_of_fields; fldi++) {
          char *colname = dbcolname(rwrap->client, fldi+1);
          VALUE field = symbolize_keys ? ID2SYM(rb_intern(colname)) : rb_obj_freeze(ENCODED_STR_NEW2(colname));
          rb_ary_store(fields, fldi, field);
        }
        /* Store the fields. */
        if (rwrap->number_of_results == 0) {
          rwrap->fields = fields;
        } else if (rwrap->number_of_results == 1) {
          VALUE multi_rs_fields = rb_ary_new();
          rb_ary_store(multi_rs_fields, 0, rwrap->fields);
          rb_ary_store(multi_rs_fields, 1, fields);
          rwrap->fields = multi_rs_fields;
        } else {
          rb_ary_store(rwrap->fields, rwrap->number_of_results, fields);
        }
        /* Create rows for this result set. */
        unsigned long rowi = 0;
        VALUE result = rb_ary_new();
        while (dbnextrow(rwrap->client) != NO_MORE_ROWS) {
          VALUE row = rb_tinytds_result_fetch_row(self, timezone, symbolize_keys, as_array);
          if (cache_rows)
            rb_ary_store(result, rowi, row);
          if (!NIL_P(block))
            rb_yield(row);
          if (first)
            dbcanquery(rwrap->client);
          rowi++;
        }
        rwrap->number_of_rows = rowi;
        /* Store the result. */
        if (rwrap->number_of_results == 0) {
          rwrap->results = result;
        } else if (rwrap->number_of_results == 1) {
          VALUE multi_resultsets = rb_ary_new();
          rb_ary_store(multi_resultsets, 0, rwrap->results);
          rb_ary_store(multi_resultsets, 1, result);
          rwrap->results = multi_resultsets;
        } else {
          rb_ary_store(rwrap->results, rwrap->number_of_results, result);
        }
        /* Record the result set */
        rwrap->number_of_results = rwrap->number_of_results + 1;
      }
      dbresults_rc = dbresults(rwrap->client);
    }
    if (dbresults_rc == FAIL) {
      // TODO: Account for something in the dbresults() while loop set the return code to FAIL.
      rb_warn("TinyTds: Something in the dbresults() while loop set the return code to FAIL.\n");
    }
  } else if (!NIL_P(block)) {
    unsigned long i;
    for (i = 0; i < rwrap->number_of_rows; i++) {
      rb_yield(rb_ary_entry(rwrap->results, i));
    }
  }
  return rwrap->results;
}

static VALUE rb_tinytds_result_fields(VALUE self) {
  GET_RESULT_WRAPPER(self);
  return rwrap->fields;
}

static VALUE rb_tinytds_result_cancel(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client)
    dbsqlok(rwrap->client);
    dbcancel(rwrap->client);
  return Qtrue;
}

static VALUE rb_tinytds_result_do(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client) {
    dbsqlok(rwrap->client);
    dbcancel(rwrap->client);
    return LONG2NUM((long)dbcount(rwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_result_affected_rows(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client) {
    return LONG2NUM((long)dbcount(rwrap->client));
  } else {
    return Qnil;
  }
}

/* Duplicated in client.c */
static VALUE rb_tinytds_result_return_code(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client && dbhasretstat(rwrap->client)) {
    return LONG2NUM((long)dbretstatus(rwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_result_insert(VALUE self) {
  GET_RESULT_WRAPPER(self);
  if (rwrap->client) {
    dbsqlok(rwrap->client);
    dbcancel(rwrap->client);
    VALUE identity = Qnil;
    dbcmd(rwrap->client, "SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident");
    if (dbsqlexec(rwrap->client) != FAIL && dbresults(rwrap->client) != FAIL && DBROWS(rwrap->client) != FAIL) {
      while (dbnextrow(rwrap->client) != NO_MORE_ROWS) {
        int col = 1;
        BYTE *data = dbdata(rwrap->client, col);
        DBINT data_len = dbdatlen(rwrap->client, col);
        int null_val = ((data == NULL) && (data_len == 0));
        if (!null_val)
          identity = LONG2NUM(*(long *)data);
      }
    }
    return identity;
  } else {
    return Qnil;
  }
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
  rb_define_method(cTinyTdsResult, "do", rb_tinytds_result_do, 0);
  rb_define_method(cTinyTdsResult, "affected_rows", rb_tinytds_result_affected_rows, 0);
  rb_define_method(cTinyTdsResult, "return_code", rb_tinytds_result_return_code, 0);
  rb_define_method(cTinyTdsResult, "insert", rb_tinytds_result_insert, 0);
  /* Intern String Helpers */
  intern_new = rb_intern("new");
  intern_utc = rb_intern("utc");
  intern_local = rb_intern("local");
  intern_merge = rb_intern("merge");
  intern_localtime = rb_intern("localtime");
  intern_civil = rb_intern("civil");
  intern_new_offset = rb_intern("new_offset");
  intern_plus = rb_intern("+");
  intern_divide = rb_intern("/");
  intern_Rational = rb_intern("Rational");
  /* Symbol Helpers */
  sym_symbolize_keys = ID2SYM(rb_intern("symbolize_keys"));
  sym_as = ID2SYM(rb_intern("as"));
  sym_array = ID2SYM(rb_intern("array"));
  sym_cache_rows = ID2SYM(rb_intern("cache_rows"));
  sym_first = ID2SYM(rb_intern("first"));
  sym_local = ID2SYM(intern_local);
  sym_utc = ID2SYM(intern_utc);
  sym_timezone = ID2SYM(rb_intern("timezone"));
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
  /* Ruby version flags */
  opt_ruby_186 = (rb_eval_string("RUBY_VERSION == '1.8.6'") == Qtrue) ? 1 : 0;
  /* Encoding */
  #ifdef HAVE_RUBY_ENCODING_H
    binaryEncoding = rb_enc_find("binary");
  #endif
}
