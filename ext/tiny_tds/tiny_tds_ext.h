#ifndef TINYTDS_EXT
#define TINYTDS_EXT

#undef MSDBLIB
#define SYBDBLIB

#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/thread.h>
#include <sybfront.h>
#include <sybdb.h>

#include <./error.h>
#include <./client.h>
#include <./result.h>

#endif
