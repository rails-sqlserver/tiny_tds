
#ifndef TINYTDS_ERROR_H
#define TINYTDS_ERROR_H

static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;

void init_tinytds_error();
VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, int cancel, char *error, char *source, int severity, int dberr, int oserr);


#endif
