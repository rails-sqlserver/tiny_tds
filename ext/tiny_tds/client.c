#include <tiny_tds_ext.h>
#include <client.h>
#include <errno.h>


VALUE cTinyTdsClient;
extern VALUE mTinyTds, cTinyTdsError;
static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;

#define GET_CLIENT(self) \
  tinytds_client_wrapper *wrapper; \
  Data_Get_Struct(self, tinytds_client_wrapper, wrapper)




// Lib Backend (Helpers)

static VALUE rb_tinytds_raise_error(char *error, char *source, int severity, int dberr, int oserr) {
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


// Lib Backend (Allocatoin & Handlers)

int tinytds_err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {  
  // - Abort the program, or
  // - Return an error code and mark the DBPROCESS as “dead” (making it unusable), or
  // - Cancel the operation that caused the error, or
  // - Keep trying (in the case of a timeout error).
  
  static char *source = "error";
  if (dberr == SYBESMSG)
    return INT_CONTINUE;
  rb_tinytds_raise_error(dberrstr, source, severity, dberr, oserr);
  
  // if ((dbproc == NULL) || (dbdead(dbproc)))
  //   return INT_EXIT;
  // if (oserr != DBNOERR) {
  //   return INT_CANCEL;
  // }
  return INT_CONTINUE;
}

int tinytds_msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line) {
  static char *source = "message";
  if (severity)
    rb_tinytds_raise_error(msgtext, source, severity, msgno, msgstate);
  return 0;
}

static void rb_tinytds_client_mark(void *wrapper) {
  tinytds_client_wrapper *w = wrapper;
  if (w) {
    
  }
}

static void rb_tinytds_client_free(void *ptr) {
  tinytds_client_wrapper *wrapper = (tinytds_client_wrapper *)ptr;
  if (wrapper->login)
    dbloginfree(wrapper->login);
  if (wrapper->client && !wrapper->closed)
    dbclose(wrapper->client);
  xfree(ptr);
}

static VALUE allocate(VALUE klass) {
  VALUE obj;
  tinytds_client_wrapper *wrapper;
  obj = Data_Make_Struct(klass, tinytds_client_wrapper, rb_tinytds_client_mark, rb_tinytds_client_free, wrapper);
  wrapper->closed = 1;
  return obj;
}


// TinyTds::Client (public) 

static VALUE rb_tinytds_tds_version(VALUE self) {
  GET_CLIENT(self);
  return INT2FIX(dbtds(wrapper->client));
}


// TinyTds::Client (protected) 

static VALUE rb_tinytds_connect(VALUE self, VALUE user, VALUE pass, VALUE host, VALUE database, VALUE app, VALUE version, VALUE ltimeout, VALUE timeout) {
  if (dbinit() == FAIL) {
    rb_raise(cTinyTdsError, "failed dbinit() function");
    return self;
  }
  dberrhandle(tinytds_err_handler);
  dbmsghandle(tinytds_msg_handler);
  GET_CLIENT(self);
  wrapper->login = dblogin();
  if (!NIL_P(user))
    dbsetluser(wrapper->login, StringValuePtr(user));
  if (!NIL_P(pass))
    dbsetlpwd(wrapper->login, StringValuePtr(pass));
  if (!NIL_P(app))
    dbsetlapp(wrapper->login, StringValuePtr(app));
  if (!NIL_P(version))
    dbsetlversion(wrapper->login, NUM2INT(version));
  if (!NIL_P(ltimeout))
    dbsetlogintime(NUM2INT(ltimeout));
  if (!NIL_P(timeout))
    dbsettime(NUM2INT(timeout));
  wrapper->client = dbopen(wrapper->login, StringValuePtr(host));
  if (wrapper->client)
    wrapper->closed = 0;
  return self;
}


// Lib Init

void init_tinytds_client() {
  cTinyTdsClient = rb_define_class_under(mTinyTds, "Client", rb_cObject);
  rb_define_alloc_func(cTinyTdsClient, allocate);
  /* Define TinyTds::Client Public Methods */
  rb_define_method(cTinyTdsClient, "tds_version", rb_tinytds_tds_version, 0);
  /* Define TinyTds::Client Protected Methods */
  rb_define_protected_method(cTinyTdsClient, "connect", rb_tinytds_connect, 8);
  /* Intern TinyTds::Error Accessors */
  intern_source_eql = rb_intern("source=");
  intern_severity_eql = rb_intern("severity=");
  intern_db_error_number_eql = rb_intern("db_error_number=");
  intern_os_error_number_eql = rb_intern("os_error_number=");
}


