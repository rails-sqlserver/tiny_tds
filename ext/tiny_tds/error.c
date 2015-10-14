
#include <tiny_tds_ext.h>

extern VALUE cTinyTdsError;
static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;

VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, int cancel, char *error, char *source, int severity, int dberr, int oserr) {
  intern_source_eql = rb_intern("source=");
  intern_severity_eql = rb_intern("severity=");
  intern_db_error_number_eql = rb_intern("db_error_number=");
  intern_os_error_number_eql = rb_intern("os_error_number=");
  GET_CLIENT_USERDATA(dbproc);
  if (cancel && !dbdead(dbproc) && userdata && !userdata->closed) {
    userdata->dbsqlok_sent = 1;
    dbsqlok(dbproc);
    userdata->dbcancel_sent = 1;
    dbcancel(dbproc);
  }
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


// Lib Init

void init_tinytds_error() {
  intern_source_eql = rb_intern("source=");
  intern_severity_eql = rb_intern("severity=");
  intern_db_error_number_eql = rb_intern("db_error_number=");
  intern_os_error_number_eql = rb_intern("os_error_number=");
}
