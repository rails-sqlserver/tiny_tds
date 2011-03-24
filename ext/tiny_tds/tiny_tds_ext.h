#ifndef TINYTDS_EXT
#define TINYTDS_EXT

#undef MSDBLIB
#define SYBDBLIB

#include <ruby.h>
#include <sybfront.h>
#include <sybdb.h>

#ifdef HAVE_RUBY_ENCODING_H
#include <ruby/encoding.h>
#endif

#include <client.h>
#include <result.h>

#endif
