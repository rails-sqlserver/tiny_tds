
#include <tiny_tds_ext.h>
#include <client.h>
#include <errno.h>

VALUE cTinyTdsClient;
extern VALUE mTinyTds, cTinyTdsError;
static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;
static ID intern_new, intern_dup, intern_transpose_iconv_encoding, intern_local_offset, intern_gsub;
VALUE opt_escape_regex, opt_escape_dblquote;

// Lib Macros

#define GET_CLIENT_WRAPPER(self) \
  tinytds_client_wrapper *cwrap; \
  Data_Get_Struct(self, tinytds_client_wrapper, cwrap)

#define REQUIRE_OPEN_CLIENT(cwrap) \
  if(cwrap->closed) { \
    rb_raise(cTinyTdsError, "closed connection"); \
    return Qnil; \
  }


// Lib Backend (Helpers)

static VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, int cancel, char *error, char *source, int severity, int dberr, int oserr) {
  if (cancel) { dbsqlok(dbproc); dbcancel(dbproc); }
  VALUE e = rb_exc_new2(cTinyTdsError, error);
  rb_funcall(e, intern_source_eql, 1, rb_str_new2(source));
  if (severity)
    rb_funcall(e, intern_severity_eql, 1, INT2FIX(severity));
  if (dberr)
    rb_funcall(e, intern_db_error_number_eql, 1, INT2FIX(dberr));
  if (oserr)
    rb_funcall(e, intern_os_error_number_eql, 1, INT2FIX(oserr));  
  rb_exc_raise(e);
  return Qnil;
}


// Lib Backend (Memory Management & Handlers)

int tinytds_err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {  
  static char *source = "error";
  if (dberr == SYBESMSG)
    return INT_CONTINUE;
  rb_tinytds_raise_error(dbproc, 0, dberrstr, source, severity, dberr, oserr);
  return INT_CONTINUE;
}

int tinytds_msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line) {
  static char *source = "message";
  if (severity)
    rb_tinytds_raise_error(dbproc, 1, msgtext, source, severity, msgno, msgstate);
  return 0;
}

static void rb_tinytds_client_mark(void *ptr) {
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;
  if (cwrap) {
    rb_gc_mark(cwrap->charset);
  }
}

static void rb_tinytds_client_free(void *ptr) {
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;
  if (cwrap->login)
    dbloginfree(cwrap->login);
  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->closed = 1;
  }
  xfree(ptr);
}

static VALUE allocate(VALUE klass) {
  VALUE obj;
  tinytds_client_wrapper *cwrap;
  obj = Data_Make_Struct(klass, tinytds_client_wrapper, rb_tinytds_client_mark, rb_tinytds_client_free, cwrap);
  cwrap->closed = 1;
  cwrap->charset = Qnil;
  return obj;
}


// TinyTds::Client (public) 

static VALUE rb_tinytds_tds_version(VALUE self) {
  GET_CLIENT_WRAPPER(self);
  return INT2FIX(dbtds(cwrap->client));
}

static VALUE rb_tinytds_close(VALUE self) {
  GET_CLIENT_WRAPPER(self);
  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->closed = 1;
  }
  return Qtrue;
}

static VALUE rb_tinytds_closed(VALUE self) {
  GET_CLIENT_WRAPPER(self);
  return cwrap->closed ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_execute(VALUE self, VALUE sql) {
  GET_CLIENT_WRAPPER(self);
  REQUIRE_OPEN_CLIENT(cwrap);
  dbcmd(cwrap->client, StringValuePtr(sql));
  if (dbsqlexec(cwrap->client) == FAIL) {
    // TODO: Account for dbsqlexec() returned FAIL.
    rb_warn("TinyTds: dbsqlexec() returned FAIL.\n");
    return Qfalse;
  }
  VALUE result = rb_tinytds_new_result_obj(cwrap->client);
  rb_iv_set(result, "@query_options", rb_funcall(rb_iv_get(self, "@query_options"), intern_dup, 0));
  GET_RESULT_WRAPPER(result);
  rwrap->local_offset = rb_funcall(cTinyTdsClient, intern_local_offset, 0);
  #ifdef HAVE_RUBY_ENCODING_H
    rwrap->encoding = cwrap->encoding;
  #endif
  return result;  
}

static VALUE rb_tinytds_charset(VALUE self) {
  GET_CLIENT_WRAPPER(self);
  return cwrap->charset;
}

static VALUE rb_tinytds_encoding(VALUE self) {
  GET_CLIENT_WRAPPER(self);
  #ifdef HAVE_RUBY_ENCODING_H
    return rb_enc_from_encoding(cwrap->encoding);
  #else
    return Qnil;
  #endif
}

static VALUE rb_tinytds_escape(VALUE self, VALUE string) {
  Check_Type(string, T_STRING);
  GET_CLIENT_WRAPPER(self);
  VALUE new_string = rb_funcall(string, intern_gsub, 2, opt_escape_regex, opt_escape_dblquote);
  #ifdef HAVE_RUBY_ENCODING_H
    rb_enc_associate(new_string, cwrap->encoding);
  #endif
  return new_string;
}


// TinyTds::Client (protected) 

static VALUE rb_tinytds_connect(VALUE self, VALUE user, VALUE pass, VALUE host, VALUE database, VALUE app, VALUE version, VALUE ltimeout, VALUE timeout, VALUE charset) {
  if (dbinit() == FAIL) {
    rb_raise(cTinyTdsError, "failed dbinit() function");
    return self;
  }
  dberrhandle(tinytds_err_handler);
  dbmsghandle(tinytds_msg_handler);
  GET_CLIENT_WRAPPER(self);
  cwrap->login = dblogin();
  if (!NIL_P(user))
    dbsetluser(cwrap->login, StringValuePtr(user));
  if (!NIL_P(pass))
    dbsetlpwd(cwrap->login, StringValuePtr(pass));
  if (!NIL_P(app))
    dbsetlapp(cwrap->login, StringValuePtr(app));
  if (!NIL_P(version))
    dbsetlversion(cwrap->login, NUM2INT(version));
  if (!NIL_P(ltimeout))
    dbsetlogintime(NUM2INT(ltimeout));
  if (!NIL_P(timeout))
    dbsettime(NUM2INT(timeout));
  if (!NIL_P(charset))
    DBSETLCHARSET(cwrap->login, StringValuePtr(charset));
  cwrap->client = dbopen(cwrap->login, StringValuePtr(host));
  if (cwrap->client) {
    cwrap->closed = 0;
    cwrap->charset = charset;
    #ifdef HAVE_RUBY_ENCODING_H
      VALUE transposed_encoding = rb_funcall(cTinyTdsClient, intern_transpose_iconv_encoding, 1, charset);
      cwrap->encoding = rb_enc_find(StringValuePtr(transposed_encoding));
    #endif
  }
  return self;
}


// Lib Init

void init_tinytds_client() {
  cTinyTdsClient = rb_define_class_under(mTinyTds, "Client", rb_cObject);
  rb_define_alloc_func(cTinyTdsClient, allocate);
  /* Define TinyTds::Client Public Methods */
  rb_define_method(cTinyTdsClient, "tds_version", rb_tinytds_tds_version, 0);
  rb_define_method(cTinyTdsClient, "close", rb_tinytds_close, 0);
  rb_define_method(cTinyTdsClient, "closed?", rb_tinytds_closed, 0);
  rb_define_method(cTinyTdsClient, "execute", rb_tinytds_execute, 1);
  rb_define_method(cTinyTdsClient, "charset", rb_tinytds_charset, 0);
  rb_define_method(cTinyTdsClient, "encoding", rb_tinytds_encoding, 0);
  rb_define_method(cTinyTdsClient, "escape", rb_tinytds_escape, 1);
  /* Define TinyTds::Client Protected Methods */
  rb_define_protected_method(cTinyTdsClient, "connect", rb_tinytds_connect, 9);
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
  /* Escape Regexp Global */
  opt_escape_regex = rb_funcall(rb_cRegexp, intern_new, 1, rb_str_new2("\\\'"));
  opt_escape_dblquote = rb_str_new2("''");
  rb_global_variable(&opt_escape_regex);
  rb_global_variable(&opt_escape_dblquote);
}


