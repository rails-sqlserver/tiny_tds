#include <tiny_tds_ext.h>
#include <errno.h>

VALUE cTinyTdsClient;
extern VALUE mTinyTds, cTinyTdsError;
static ID sym_username, sym_password, sym_dataserver, sym_database, sym_appname, sym_tds_version, sym_login_timeout, sym_timeout, sym_encoding, sym_azure, sym_contained, sym_use_utf16, sym_message_handler;
static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;
static ID intern_new, intern_dup, intern_transpose_iconv_encoding, intern_local_offset, intern_gsub, intern_call;
VALUE opt_escape_regex, opt_escape_dblquote;

static ID id_ivar_fields, id_ivar_rows, id_ivar_return_code, id_ivar_affected_rows, id_ivar_default_query_options, intern_bigd, intern_divide;
static ID sym_as, sym_array, sym_timezone, sym_empty_sets, sym_local, sym_utc, intern_utc, intern_local, intern_as, intern_empty_sets, intern_timezone;
static VALUE cTinyTdsResult, cKernel, cDate;

rb_encoding *binaryEncoding;
VALUE opt_onek, opt_onebil, opt_float_zero, opt_four, opt_tenk;

static void rb_tinytds_client_mark(void *ptr)
{
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;

  if (cwrap) {
    rb_gc_mark(cwrap->charset);
  }
}

static void rb_tinytds_client_free(void *ptr)
{
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;

  if (cwrap->login) {
    dbloginfree(cwrap->login);
  }

  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->client = NULL;
    cwrap->closed = 1;
    cwrap->userdata->closed = 1;
  }

  xfree(cwrap->userdata);
  xfree(ptr);
}

static size_t tinytds_client_wrapper_size(const void* data)
{
  return sizeof(tinytds_client_wrapper);
}

static const rb_data_type_t tinytds_client_wrapper_type = {
  .wrap_struct_name = "tinytds_client_wrapper",
  .function = {
    .dmark = rb_tinytds_client_mark,
    .dfree = rb_tinytds_client_free,
    .dsize = tinytds_client_wrapper_size,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

// Lib Macros

#define GET_CLIENT_WRAPPER(self) \
  tinytds_client_wrapper *cwrap; \
  TypedData_Get_Struct(self, tinytds_client_wrapper, &tinytds_client_wrapper_type, cwrap)

#ifdef _WIN32
  #define LONG_LONG_FORMAT "I64d"
#else
  #define LONG_LONG_FORMAT "lld"
#endif

#define ENCODED_STR_NEW(_data, _len) ({ \
  VALUE _val = rb_str_new((char *)_data, (long)_len); \
  rb_enc_associate(_val, cwrap->encoding); \
  _val; \
})
#define ENCODED_STR_NEW2(_data2) ({ \
  VALUE _val = rb_str_new2((char *)_data2); \
  rb_enc_associate(_val, cwrap->encoding); \
  _val; \
})

// Lib Backend (Helpers)

VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, tinytds_errordata error)
{
  VALUE e;
  GET_CLIENT_USERDATA(dbproc);

  if (error.cancel && !dbdead(dbproc) && userdata && !userdata->closed) {
    userdata->dbsqlok_sent = 1;
    dbsqlok(dbproc);
    userdata->dbcancel_sent = 1;
    dbcancel(dbproc);
  }

  e = rb_exc_new2(cTinyTdsError, error.error);
  rb_funcall(e, intern_source_eql, 1, rb_str_new2(error.source));

  if (error.severity) {
    rb_funcall(e, intern_severity_eql, 1, INT2FIX(error.severity));
  }

  if (error.dberr) {
    rb_funcall(e, intern_db_error_number_eql, 1, INT2FIX(error.dberr));
  }

  if (error.oserr) {
    rb_funcall(e, intern_os_error_number_eql, 1, INT2FIX(error.oserr));
  }

  if (error.severity <= 10 && error.is_message) {
    VALUE message_handler = userdata && userdata->message_handler ? userdata->message_handler : Qnil;

    if (message_handler && message_handler != Qnil && rb_respond_to(message_handler, intern_call) != 0) {
      rb_funcall(message_handler, intern_call, 1, e);
    }

    return Qnil;
  }

  rb_exc_raise(e);
  return Qnil;
}

static void rb_tinytds_client_reset_userdata(tinytds_client_userdata *userdata)
{
  userdata->timing_out = 0;
  userdata->dbsql_sent = 0;
  userdata->dbsqlok_sent = 0;
  userdata->dbcancel_sent = 0;
  userdata->nonblocking = 0;
  // the following is mainly done for consistency since the values are reset accordingly in nogvl_setup/cleanup.
  // the nonblocking_errors array does not need to be freed here. That is done as part of nogvl_cleanup.
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors_size = 0;
}

// code part used to invoke FreeTDS functions with releasing the Ruby GVL
// basically, while FreeTDS is interacting with the SQL server, other Ruby code can be executed
#define NOGVL_DBCALL(_dbfunction, _client) ( \
  (RETCODE)(intptr_t)rb_thread_call_without_gvl( \
    (void *(*)(void *))_dbfunction, _client, \
    (rb_unblock_function_t*)dbcancel_ubf, _client ) \
)

static void dbcancel_ubf(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  dbcancel(client);
  userdata->dbcancel_sent = 1;
}

static void nogvl_setup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 1;
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors = malloc(ERRORS_STACK_INIT_SIZE * sizeof(tinytds_errordata));
  userdata->nonblocking_errors_size = ERRORS_STACK_INIT_SIZE;
}

static void nogvl_cleanup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 0;
  userdata->timing_out = 0;
  /*
  Now that the blocking operation is done, we can finally throw any
  exceptions based on errors from SQL Server.
  */
  short int i;

  for (i = 0; i < userdata->nonblocking_errors_length; i++) {
    tinytds_errordata error = userdata->nonblocking_errors[i];

    // lookahead to drain any info messages ahead of raising error
    if (!error.is_message) {
      short int j;

      for (j = i; j < userdata->nonblocking_errors_length; j++) {
        tinytds_errordata msg_error = userdata->nonblocking_errors[j];

        if (msg_error.is_message) {
          rb_tinytds_raise_error(client, msg_error);
        }
      }
    }

    rb_tinytds_raise_error(client, error);
  }

  free(userdata->nonblocking_errors);
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors_size = 0;
}

static RETCODE nogvl_dbnextrow(DBPROCESS * client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbnextrow, client);
  nogvl_cleanup(client);
  return retcode;
}

static RETCODE nogvl_dbresults(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbresults, client);
  nogvl_cleanup(client);
  return retcode;
}

static RETCODE nogvl_dbsqlexec(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlexec, client);
  nogvl_cleanup(client);
  return retcode;
}

static RETCODE nogvl_dbsqlok(DBPROCESS *client)
{
  int retcode = FAIL;
  GET_CLIENT_USERDATA(client);
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlok, client);
  nogvl_cleanup(client);
  userdata->dbsqlok_sent = 1;
  return retcode;
}

// some additional helpers interacting with the SQL server
static void rb_tinytds_send_sql_to_server(tinytds_client_wrapper *cwrap, VALUE sql)
{
  rb_tinytds_client_reset_userdata(cwrap->userdata);

  if (cwrap->closed || cwrap->userdata->closed) {
    rb_raise(cTinyTdsError, "closed connection");
  }

  dbcmd(cwrap->client, StringValueCStr(sql));

  if (dbsqlsend(cwrap->client) == FAIL) {
    rb_raise(cTinyTdsError, "failed dbsqlsend() function");
  }

  cwrap->userdata->dbsql_sent = 1;
}

static RETCODE rb_tiny_tds_client_ok_helper(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);

  if (userdata->dbsqlok_sent == 0) {
    userdata->dbsqlok_retcode = nogvl_dbsqlok(client);
  }

  return userdata->dbsqlok_retcode;
}

static void rb_tinytds_client_cancel_results(DBPROCESS * client)
{
  GET_CLIENT_USERDATA(client);
  dbcancel(client);
  userdata->dbcancel_sent = 1;
  userdata->dbsql_sent = 0;
}

static void rb_tinytds_result_exec_helper(DBPROCESS *client)
{
  RETCODE dbsqlok_rc = rb_tiny_tds_client_ok_helper(client);

  if (dbsqlok_rc == SUCCEED) {
    /*
    This is to just process each result set. Commands such as backup and
    restore are not done when the first result set is returned, so we need to
    exhaust the result sets before it is complete.
    */
    while (nogvl_dbresults(client) == SUCCEED) {
      /*
      If we don't loop through each row for calls to TinyTds::Client.do that
      actually do return result sets, we will trigger error 20019 about trying
      to execute a new command with pending results. Oh well.
      */
      while (dbnextrow(client) != NO_MORE_ROWS);
    }
  }

  rb_tinytds_client_cancel_results(client);
}

// Lib Backend (Memory Management & Handlers)
static void push_userdata_error(tinytds_client_userdata *userdata, tinytds_errordata error)
{
  // reallocate memory for the array as needed
  if (userdata->nonblocking_errors_size == userdata->nonblocking_errors_length) {
    userdata->nonblocking_errors_size *= 2;
    userdata->nonblocking_errors = realloc(userdata->nonblocking_errors, userdata->nonblocking_errors_size * sizeof(tinytds_errordata));
  }

  userdata->nonblocking_errors[userdata->nonblocking_errors_length] = error;
  userdata->nonblocking_errors_length++;
}

int tinytds_err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{
  static const char *source = "error";
  /* Everything should cancel by default */
  int return_value = INT_CANCEL;
  int cancel = 0;

  GET_CLIENT_USERDATA(dbproc);

  /* These error codes are documented in include/sybdb.h in FreeTDS */
  switch(dberr) {

    /* We don't want to raise these as a ruby exception for various reasons */
    case 100: /* SYBEVERDOWN, indicating the connection can only be v7.1 */
    case SYBESEOF: /* Usually accompanied by another more useful error */
    case SYBESMSG: /* Generic "check messages from server" error */
    case SYBEICONVI: /* Just return ?s to the client, as explained in readme */
      return return_value;

    case SYBEICONVO:
      dbfreebuf(dbproc);
      return return_value;

    case SYBETIME:

      /*
      SYBETIME is the only error that can send INT_TIMEOUT or INT_CONTINUE,
      but we don't ever want to automatically retry. Instead have the app
      decide what to do.
      */
      if (userdata && userdata->timing_out) {
        return INT_CANCEL;
      }

      // userdata will not be set if hitting timeout during login so check for it first
      if (userdata) {
        userdata->timing_out = 1;
      }

      return_value = INT_TIMEOUT;
      cancel = 1;
      break;

    case SYBEWRIT:

      /* Write errors may happen after we abort a statement */
      if (userdata && (userdata->dbsqlok_sent || userdata->dbcancel_sent)) {
        return return_value;
      }

      cancel = 1;
      break;
  }

  tinytds_errordata error_data = {
    .is_message = 0,
    .cancel = cancel,
    .severity = severity,
    .dberr = dberr,
    .oserr = oserr
  };
  strncpy(error_data.error, dberrstr, ERROR_MSG_SIZE);
  strncpy(error_data.source, source, ERROR_MSG_SIZE);

  /*
  When in non-blocking mode we need to store the exception data to throw it
  once the blocking call returns, otherwise we will segfault ruby since part
  of the contract of the ruby non-blocking indicator is that you do not call
  any of the ruby C API.
  */
  if (userdata && userdata->nonblocking) {
    if (cancel && !dbdead(dbproc) && !userdata->closed) {
      dbcancel(dbproc);
      userdata->dbcancel_sent = 1;
    }

    push_userdata_error(userdata, error_data);
  } else {
    rb_tinytds_raise_error(dbproc, error_data);
  }

  return return_value;
}

int tinytds_msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line)
{
  static const char *source = "message";
  GET_CLIENT_USERDATA(dbproc);

  int is_message_an_error = severity > 10 ? 1 : 0;

  tinytds_errordata error_data = {
    .is_message = !is_message_an_error,
    .cancel = is_message_an_error,
    .severity = severity,
    .dberr = msgno,
    .oserr = msgstate
  };
  strncpy(error_data.error, msgtext, ERROR_MSG_SIZE);
  strncpy(error_data.source, source, ERROR_MSG_SIZE);

  // See tinytds_err_handler() for info about why we do this
  if (userdata && userdata->nonblocking) {
    /*
    In the case of non-blocking command batch execution we can receive multiple messages
    (including errors). We keep track of those here so they can be processed once the
    non-blocking call returns.
    */
    push_userdata_error(userdata, error_data);

    if (is_message_an_error && !dbdead(dbproc) && !userdata->closed) {
      dbcancel(dbproc);
      userdata->dbcancel_sent = 1;
    }
  } else {
    rb_tinytds_raise_error(dbproc, error_data);
  }

  return 0;
}

/*
Used by dbsetinterrupt -
This gets called periodically while waiting on a read from the server
Right now, we only care about cases where a read from the server is
taking longer than the specified timeout and dbcancel is not working.
In these cases we decide that we actually want to handle the interrupt
*/
static int check_interrupt(void *ptr)
{
  GET_CLIENT_USERDATA((DBPROCESS *)ptr);
  return userdata->timing_out;
}

/*
Used by dbsetinterrupt -
This gets called if check_interrupt returns TRUE.
Right now, this is only used in cases where a read from the server is
taking longer than the specified timeout and dbcancel is not working.
Return INT_CANCEL to abort the current command batch.
*/
static int handle_interrupt(void *ptr)
{
  GET_CLIENT_USERDATA((DBPROCESS *)ptr);

  if (userdata->timing_out) {
    return INT_CANCEL;
  }

  return INT_CONTINUE;
}

static VALUE allocate(VALUE klass)
{
  VALUE obj;
  tinytds_client_wrapper *cwrap;
  obj = TypedData_Make_Struct(klass, tinytds_client_wrapper, &tinytds_client_wrapper_type, cwrap);
  cwrap->closed = 1;
  cwrap->charset = Qnil;
  cwrap->userdata = malloc(sizeof(tinytds_client_userdata));
  cwrap->userdata->closed = 1;
  rb_tinytds_client_reset_userdata(cwrap->userdata);
  return obj;
}


// TinyTds::Client (public)

static VALUE rb_tinytds_tds_version(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return INT2FIX(dbtds(cwrap->client));
}

static VALUE rb_tinytds_close(VALUE self)
{
  GET_CLIENT_WRAPPER(self);

  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->client = NULL;
    cwrap->closed = 1;
    cwrap->userdata->closed = 1;
  }

  return Qtrue;
}

static VALUE rb_tinytds_dead(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return dbdead(cwrap->client) ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_closed(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return (cwrap->closed || cwrap->userdata->closed) ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_canceled(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->userdata->dbcancel_sent ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_sqlsent(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->userdata->dbsql_sent ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_result_fetch_value(VALUE self, ID timezone, unsigned int number_of_fields, int field_index)
{
  GET_CLIENT_WRAPPER(self);

  VALUE val = Qnil;

  int col = field_index + 1;
  int coltype = dbcoltype(cwrap->client, col);
  BYTE *data = dbdata(cwrap->client, col);
  DBINT data_len = dbdatlen(cwrap->client, col);
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
        DBTYPEINFO *data_info = dbcoltypeinfo(cwrap->client, col);
        int data_slength = (int)data_info->precision + (int)data_info->scale + 1;
        char converted_decimal[data_slength];
        dbconvert(cwrap->client, coltype, data, data_len, SYBVARCHAR, (BYTE *)converted_decimal, -1);
        val = rb_funcall(cKernel, intern_bigd, 1, rb_str_new2((char *)converted_decimal));
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
        sprintf(converted_money, "%" LONG_LONG_FORMAT, money_value);
        val = rb_funcall(cKernel, intern_bigd, 2, rb_str_new2(converted_money), opt_four);
        val = rb_funcall(val, intern_divide, 1, opt_tenk);
        break;
      }

      case SYBMONEY4: {
        DBMONEY4 *money = (DBMONEY4 *)data;
        char converted_money[20];
        sprintf(converted_money, "%f", money->mny4 / 10000.0);
        val = rb_funcall(cKernel, intern_bigd, 1, rb_str_new2(converted_money));
        break;
      }

      case SYBBINARY:
      case SYBIMAGE:
        val = rb_str_new((char *)data, (long)data_len);
        rb_enc_associate(val, binaryEncoding);
        break;

      case 36: { // SYBUNIQUE
        char converted_unique[37];
        dbconvert(cwrap->client, coltype, data, 37, SYBVARCHAR, (BYTE *)converted_unique, -1);
        val = ENCODED_STR_NEW2(converted_unique);
        break;
      }

      case SYBDATETIME4: {
        DBDATETIME new_data;
        dbconvert(cwrap->client, coltype, data, data_len, SYBDATETIME, (BYTE *)&new_data, sizeof(new_data));
        data = (BYTE *)&new_data;
        data_len = sizeof(new_data);
      }

      case SYBDATETIME: {
        DBDATEREC dr;
        dbdatecrack(cwrap->client, &dr, (DBDATETIME *)data);

        if (dr.year + dr.month + dr.day + dr.hour + dr.minute + dr.second + dr.millisecond != 0) {
          val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(dr.year), INT2NUM(dr.month), INT2NUM(dr.day), INT2NUM(dr.hour), INT2NUM(dr.minute), INT2NUM(dr.second), INT2NUM(dr.millisecond*1000));
        }

        break;
      }

      case SYBMSDATE:
      case SYBMSTIME:
      case SYBMSDATETIME2:
      case SYBMSDATETIMEOFFSET: {
        DBDATEREC2 dr2;
        dbanydatecrack(cwrap->client, &dr2, coltype, data);

        switch(coltype) {
          case SYBMSDATE: {
            val = rb_funcall(cDate, intern_new, 3, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day));
            break;
          }

          case SYBMSTIME: {
            VALUE rational_nsec = rb_Rational(INT2NUM(dr2.nanosecond), opt_onek);
            val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(1900), INT2NUM(1), INT2NUM(1), INT2NUM(dr2.hour), INT2NUM(dr2.minute), INT2NUM(dr2.second), rational_nsec);
            break;
          }

          case SYBMSDATETIME2: {
            VALUE rational_nsec = rb_Rational(INT2NUM(dr2.nanosecond), opt_onek);
            val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day), INT2NUM(dr2.hour), INT2NUM(dr2.minute), INT2NUM(dr2.second), rational_nsec);
            break;
          }

          case SYBMSDATETIMEOFFSET: {
            long long numerator = ((long)dr2.second * (long long)1000000000) + (long long)dr2.nanosecond;
            VALUE rational_sec = rb_Rational(LL2NUM(numerator), opt_onebil);
            val = rb_funcall(rb_cTime, intern_new, 7, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day), INT2NUM(dr2.hour), INT2NUM(dr2.minute), rational_sec, INT2NUM(dr2.tzone*60));
            break;
          }
        }

        break;
      }

      case SYBCHAR:
      case SYBTEXT:
        val = ENCODED_STR_NEW(data, data_len);
        break;

      case 98: { // SYBVARIANT
        if (data_len == 4) {
          val = INT2NUM(*(DBINT *)data);
          break;
        } else {
          val = ENCODED_STR_NEW(data, data_len);
          break;
        }
      }

      default:
        val = ENCODED_STR_NEW(data, data_len);
        break;
    }
  }

  return val;
}

static VALUE get_default_query_option(VALUE key)
{
  return rb_hash_aref(rb_ivar_get(cTinyTdsClient, id_ivar_default_query_options), key);
}

static VALUE rb_tinytds_return_code(VALUE self)
{
  GET_CLIENT_WRAPPER(self);

  if (cwrap->client && dbhasretstat(cwrap->client)) {
    return LONG2NUM((long)dbretstatus(cwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_affected_rows(DBPROCESS * client)
{
  return LONG2NUM((long)dbcount(client));
}

static VALUE rb_tinytds_execute(int argc, VALUE *argv, VALUE self)
{
  VALUE sql;            // The required argument (non-keyword)
  VALUE kwds;           // A hash to store keyword arguments
  ID kw_table[3];       // ID array to hold keys for keyword arguments
  VALUE kw_values[3];   // VALUE array to hold values of keyword arguments

  // Define the keyword argument names
  kw_table[0] = intern_as;
  kw_table[1] = intern_empty_sets;
  kw_table[2] = intern_timezone;

  // Extract the SQL argument (1st argument) and keyword arguments (kwargs)
  rb_scan_args(argc, argv, "1:", &sql, &kwds);
  rb_get_kwargs(kwds, kw_table, 0, 3, kw_values);

  kw_values[0] = kw_values[0] == Qundef ? get_default_query_option(sym_as) : kw_values[0];
  kw_values[1] = kw_values[1] == Qundef ? get_default_query_option(sym_empty_sets) : kw_values[1];
  kw_values[2] = kw_values[2] == Qundef ? get_default_query_option(sym_timezone) : kw_values[2];

  unsigned int as_array = 0;

  if (kw_values[0] == sym_array) {
    as_array = 1;
  }

  unsigned int empty_sets = 0;

  if (kw_values[1] == Qtrue) {
    empty_sets = 1;
  }

  VALUE timezone;

  if (kw_values[2] == sym_local) {
    timezone = intern_local;
  } else if (kw_values[2] == sym_utc) {
    timezone = intern_utc;
  } else {
    rb_warn(":timezone option must be :utc or :local - defaulting to :local");
    timezone = intern_local;
  }

  GET_CLIENT_WRAPPER(self);
  rb_tinytds_send_sql_to_server(cwrap, sql);

  VALUE result = rb_obj_alloc(cTinyTdsResult);
  VALUE rows = rb_ary_new();
  rb_ivar_set(result, id_ivar_rows, rows);

  unsigned int field_index;
  unsigned int number_of_result_sets = 0;

  VALUE key;

  unsigned int number_of_fields = 0;

  // if a user makes a nested query (e.g. "SELECT 1 as [one]; SELECT 2 as [two];")
  // this will loop multiple times
  // our fields data structure then will get to be an array of arrays
  // and rows will be an array of arrays or hashes
  // we track this loop using number_of_result_sets
  while ((rb_tiny_tds_client_ok_helper(cwrap->client) == SUCCEED) && (dbresults(cwrap->client) == SUCCEED)) {
    unsigned int has_rows = (DBROWS(cwrap->client) == SUCCEED) ? 1 : 0;

    if (has_rows || empty_sets || number_of_result_sets == 0) {
      number_of_fields = dbnumcols(cwrap->client);
      VALUE fields = rb_ary_new2(number_of_fields);

      for (field_index = 0; field_index < number_of_fields; field_index++) {
        char *colname = dbcolname(cwrap->client, field_index+1);
        VALUE field = rb_obj_freeze(ENCODED_STR_NEW2(colname));
        rb_ary_store(fields, field_index, field);
      }

      if (number_of_result_sets == 0) {
        rb_ivar_set(result, id_ivar_fields, fields);
      } else if (number_of_result_sets == 1) {
        // we encounter our second loop, so we shuffle the fields around
        VALUE multi_result_sets_fields = rb_ary_new();

        rb_ary_store(multi_result_sets_fields, 0, rb_ivar_get(result, id_ivar_fields));
        rb_ary_store(multi_result_sets_fields, 1, fields);

        rb_ivar_set(result, id_ivar_fields, multi_result_sets_fields);
      } else {
        rb_ary_push(rb_ivar_get(result, id_ivar_fields), fields);
      }
    } else {
      // it could be that
      // there are no rows to be processed
      // the user does not want empty sets to be included in their results (our default actually)
      // or we are not in the first iteration of the result loop (we always want to fill out fields on the first iteration)
      // in any case, through number_of_fields we signal the next loop that we do not want to fetch results
      number_of_fields = 0;
    }

    if ((has_rows || empty_sets) && number_of_fields > 0) {
      VALUE rows = rb_ary_new();

      while (nogvl_dbnextrow(cwrap->client) != NO_MORE_ROWS) {
        VALUE row = as_array ? rb_ary_new2(number_of_fields) : rb_hash_new();

        for (field_index = 0; field_index < number_of_fields; field_index++) {
          VALUE val = rb_tinytds_result_fetch_value(self, timezone, number_of_fields, field_index);

          if (as_array) {
            rb_ary_store(row, field_index, val);
          } else {
            if (number_of_result_sets > 0) {
              key = rb_ary_entry(rb_ary_entry(rb_ivar_get(result, id_ivar_fields), number_of_result_sets), field_index);
            } else {
              key = rb_ary_entry(rb_ivar_get(result, id_ivar_fields), field_index);
            }

            // for our current row, add a pair with the field name from our fields array and the parsed value
            rb_hash_aset(row, key, val);
          }
        }

        rb_ary_push(rows, row);
      }

      // if we have only one set of results, we overwrite @rows with our rows object here
      if (number_of_result_sets == 0) {
        rb_ivar_set(result, id_ivar_rows, rows);
      } else if (number_of_result_sets == 1) {
        // when encountering the second result set, we have to adjust @rows to be an array of arrays
        VALUE multi_result_set_results = rb_ary_new();

        rb_ary_store(multi_result_set_results, 0, rb_ivar_get(result, id_ivar_rows));
        rb_ary_store(multi_result_set_results, 1, rows);

        rb_ivar_set(result, id_ivar_rows, multi_result_set_results);
      } else {
        // when encountering two or more results sets, the structure of @rows has already been adjusted
        // to be an array of arrays (with the previous condition)
        rb_ary_push(rb_ivar_get(result, id_ivar_rows), rows);
      }

      number_of_result_sets++;
    }
  }

  rb_ivar_set(result, id_ivar_affected_rows, rb_tinytds_affected_rows(cwrap->client));
  rb_ivar_set(result, id_ivar_return_code, rb_tinytds_return_code(self));
  rb_tinytds_client_cancel_results(cwrap->client);

  return result;
}

static VALUE rb_tiny_tds_insert(VALUE self, VALUE sql)
{
  VALUE identity = Qnil;
  GET_CLIENT_WRAPPER(self);
  rb_tinytds_send_sql_to_server(cwrap, sql);
  rb_tinytds_result_exec_helper(cwrap->client);

  // prepare second query to fetch last identity
  dbcmd(cwrap->client, cwrap->identity_insert_sql);

  if (
    nogvl_dbsqlexec(cwrap->client) != FAIL
    && nogvl_dbresults(cwrap->client) != FAIL
    && DBROWS(cwrap->client) != FAIL
  ) {
    while (nogvl_dbnextrow(cwrap->client) != NO_MORE_ROWS) {
      int col = 1;
      BYTE *data = dbdata(cwrap->client, col);
      DBINT data_len = dbdatlen(cwrap->client, col);
      int null_val = ((data == NULL) && (data_len == 0));

      if (!null_val) {
        identity = LL2NUM(*(DBBIGINT *)data);
      }
    }
  }

  return identity;
}

static VALUE rb_tiny_tds_do(VALUE self, VALUE sql)
{
  GET_CLIENT_WRAPPER(self);
  rb_tinytds_send_sql_to_server(cwrap, sql);
  rb_tinytds_result_exec_helper(cwrap->client);

  return rb_tinytds_affected_rows(cwrap->client);
}

static VALUE rb_tinytds_charset(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->charset;
}

static VALUE rb_tinytds_encoding(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return rb_enc_from_encoding(cwrap->encoding);
}

static VALUE rb_tinytds_escape(VALUE self, VALUE string)
{
  VALUE new_string;
  GET_CLIENT_WRAPPER(self);

  Check_Type(string, T_STRING);
  new_string = rb_funcall(string, intern_gsub, 2, opt_escape_regex, opt_escape_dblquote);
  rb_enc_associate(new_string, cwrap->encoding);
  return new_string;
}

static VALUE rb_tinytds_identity_sql(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return rb_str_new2(cwrap->identity_insert_sql);
}



// TinyTds::Client (protected)

static VALUE rb_tinytds_connect(VALUE self, VALUE opts)
{
  /* Parsing options hash to local vars. */
  VALUE user, pass, dataserver, database, app, version, ltimeout, timeout, charset, azure, contained, use_utf16;
  GET_CLIENT_WRAPPER(self);

  user = rb_hash_aref(opts, sym_username);
  pass = rb_hash_aref(opts, sym_password);
  dataserver = rb_hash_aref(opts, sym_dataserver);
  database = rb_hash_aref(opts, sym_database);
  app = rb_hash_aref(opts, sym_appname);
  version = rb_hash_aref(opts, sym_tds_version);
  ltimeout = rb_hash_aref(opts, sym_login_timeout);
  timeout = rb_hash_aref(opts, sym_timeout);
  charset = rb_hash_aref(opts, sym_encoding);
  azure = rb_hash_aref(opts, sym_azure);
  contained = rb_hash_aref(opts, sym_contained);
  use_utf16 = rb_hash_aref(opts, sym_use_utf16);
  cwrap->userdata->message_handler = rb_hash_aref(opts, sym_message_handler);

  /* Dealing with options. */
  if (dbinit() == FAIL) {
    rb_raise(cTinyTdsError, "failed dbinit() function");
    return self;
  }

  dberrhandle(tinytds_err_handler);
  dbmsghandle(tinytds_msg_handler);
  cwrap->login = dblogin();

  if (!NIL_P(version)) {
    dbsetlversion(cwrap->login, NUM2INT(version));
  }

  if (!NIL_P(user)) {
    dbsetluser(cwrap->login, StringValueCStr(user));
  }

  if (!NIL_P(pass)) {
    dbsetlpwd(cwrap->login, StringValueCStr(pass));
  }

  if (!NIL_P(app)) {
    dbsetlapp(cwrap->login, StringValueCStr(app));
  }

  if (!NIL_P(ltimeout)) {
    dbsetlogintime(NUM2INT(ltimeout));
  }

  if (!NIL_P(charset)) {
    DBSETLCHARSET(cwrap->login, StringValueCStr(charset));
  }

  if (!NIL_P(database)) {
    if (azure == Qtrue || contained == Qtrue) {
      #ifdef DBSETLDBNAME
      DBSETLDBNAME(cwrap->login, StringValueCStr(database));
      #else

      if (azure == Qtrue) {
        rb_warn("TinyTds: :azure option is not supported in this version of FreeTDS.\n");
      }

      if (contained == Qtrue) {
        rb_warn("TinyTds: :contained option is not supported in this version of FreeTDS.\n");
      }

      #endif
    }
  }

  if (use_utf16 == Qtrue)  {
    DBSETLUTF16(cwrap->login, 1);
  }

  if (use_utf16 == Qfalse) {
    DBSETLUTF16(cwrap->login, 0);
  }

  cwrap->client = dbopen(cwrap->login, StringValueCStr(dataserver));

  if (cwrap->client) {
    if (dbtds(cwrap->client) < 11) {
      rb_raise(cTinyTdsError, "connecting with a TDS version older than 7.3!");
    }

    VALUE transposed_encoding, timeout_string;

    cwrap->closed = 0;
    cwrap->charset = charset;

    if (!NIL_P(version)) {
      dbsetversion(NUM2INT(version));
    }

    if (!NIL_P(timeout)) {
      timeout_string = rb_sprintf("%"PRIsVALUE"", timeout);

      if (dbsetopt(cwrap->client, DBSETTIME, StringValueCStr(timeout_string), 0) == FAIL) {
        dbsettime(NUM2INT(timeout));
      }
    }

    dbsetuserdata(cwrap->client, (BYTE*)cwrap->userdata);
    dbsetinterrupt(cwrap->client, check_interrupt, handle_interrupt);
    cwrap->userdata->closed = 0;

    if (!NIL_P(database) && (azure != Qtrue)) {
      dbuse(cwrap->client, StringValueCStr(database));
    }

    transposed_encoding = rb_funcall(cTinyTdsClient, intern_transpose_iconv_encoding, 1, charset);
    cwrap->encoding = rb_enc_find(StringValueCStr(transposed_encoding));
    cwrap->identity_insert_sql = "SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident";
  }

  return self;
}


// Lib Init

void init_tinytds_client()
{
  cTinyTdsClient = rb_define_class_under(mTinyTds, "Client", rb_cObject);
  rb_define_alloc_func(cTinyTdsClient, allocate);
  /* Define TinyTds::Client Public Methods */
  rb_define_method(cTinyTdsClient, "tds_version", rb_tinytds_tds_version, 0);
  rb_define_method(cTinyTdsClient, "close", rb_tinytds_close, 0);
  rb_define_method(cTinyTdsClient, "closed?", rb_tinytds_closed, 0);
  rb_define_method(cTinyTdsClient, "canceled?", rb_tinytds_canceled, 0);
  rb_define_method(cTinyTdsClient, "dead?", rb_tinytds_dead, 0);
  rb_define_method(cTinyTdsClient, "sqlsent?", rb_tinytds_sqlsent, 0);
  rb_define_method(cTinyTdsClient, "execute", rb_tinytds_execute, -1);
  rb_define_method(cTinyTdsClient, "insert", rb_tiny_tds_insert, 1);
  rb_define_method(cTinyTdsClient, "do", rb_tiny_tds_do, 1);
  rb_define_method(cTinyTdsClient, "charset", rb_tinytds_charset, 0);
  rb_define_method(cTinyTdsClient, "encoding", rb_tinytds_encoding, 0);
  rb_define_method(cTinyTdsClient, "escape", rb_tinytds_escape, 1);
  rb_define_method(cTinyTdsClient, "return_code", rb_tinytds_return_code, 0);
  rb_define_method(cTinyTdsClient, "identity_sql", rb_tinytds_identity_sql, 0);
  /* Define TinyTds::Client Protected Methods */
  rb_define_protected_method(cTinyTdsClient, "connect", rb_tinytds_connect, 1);
  /* Symbols For Connect */
  sym_username = ID2SYM(rb_intern("username"));
  sym_password = ID2SYM(rb_intern("password"));
  sym_dataserver = ID2SYM(rb_intern("dataserver"));
  sym_database = ID2SYM(rb_intern("database"));
  sym_appname = ID2SYM(rb_intern("appname"));
  sym_tds_version = ID2SYM(rb_intern("tds_version"));
  sym_login_timeout = ID2SYM(rb_intern("login_timeout"));
  sym_timeout = ID2SYM(rb_intern("timeout"));
  sym_encoding = ID2SYM(rb_intern("encoding"));
  sym_azure = ID2SYM(rb_intern("azure"));
  sym_contained = ID2SYM(rb_intern("contained"));
  sym_use_utf16 = ID2SYM(rb_intern("use_utf16"));
  sym_message_handler = ID2SYM(rb_intern("message_handler"));
  /* Intern TinyTds::Error Accessors */
  intern_source_eql = rb_intern("source=");
  intern_severity_eql = rb_intern("severity=");
  intern_db_error_number_eql = rb_intern("db_error_number=");
  intern_os_error_number_eql = rb_intern("os_error_number=");
  /* Intern Misc */
  intern_new = rb_intern("new");
  intern_dup = rb_intern("dup");
  intern_transpose_iconv_encoding = rb_intern("transpose_iconv_encoding");
  intern_local_offset = rb_intern("local_offset");
  intern_gsub = rb_intern("gsub");
  intern_call = rb_intern("call");
  /* Escape Regexp Global */
  opt_escape_regex = rb_funcall(rb_cRegexp, intern_new, 1, rb_str_new2("\\\'"));
  opt_escape_dblquote = rb_str_new2("''");

  rb_global_variable(&opt_escape_regex);
  rb_global_variable(&opt_escape_dblquote);

  intern_bigd = rb_intern("BigDecimal");
  intern_divide = rb_intern("/");
  id_ivar_fields = rb_intern("@fields");
  id_ivar_rows = rb_intern("@rows");
  id_ivar_default_query_options = rb_intern("@default_query_options");
  id_ivar_return_code = rb_intern("@return_code");
  id_ivar_affected_rows = rb_intern("@affected_rows");

  intern_as = rb_intern("as");
  intern_empty_sets = rb_intern("empty_sets");
  intern_timezone = rb_intern("timezone");
  intern_utc = rb_intern("utc");
  intern_local = rb_intern("local");

  cTinyTdsClient = rb_const_get(mTinyTds, rb_intern("Client"));
  cTinyTdsResult = rb_const_get(mTinyTds, rb_intern("Result"));
  cKernel = rb_const_get(rb_cObject, rb_intern("Kernel"));
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));

  opt_float_zero = rb_float_new((double)0);
  opt_four = INT2NUM(4);
  opt_onek = INT2NUM(1000);
  opt_tenk = INT2NUM(10000);
  opt_onebil = INT2NUM(1000000000);

  binaryEncoding = rb_enc_find("binary");

  rb_global_variable(&cTinyTdsResult);
  rb_global_variable(&opt_float_zero);

  /* Symbol Helpers */
  sym_as = ID2SYM(intern_as);
  sym_array = ID2SYM(rb_intern("array"));
  sym_timezone = ID2SYM(intern_timezone);
  sym_empty_sets = ID2SYM(intern_empty_sets);
  sym_local = ID2SYM(intern_local);
  sym_utc = ID2SYM(intern_utc);
}
