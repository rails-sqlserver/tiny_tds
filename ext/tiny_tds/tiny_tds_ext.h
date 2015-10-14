#ifndef TINYTDS_EXT
#define TINYTDS_EXT

#undef MSDBLIB
#define SYBDBLIB

#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/version.h>
#if RUBY_API_VERSION_MAJOR >= 2
  #include <ruby/thread.h>
  #endif
#include <sybfront.h>
#include <sybdb.h>

#include <client.h>
#include <result.h>

#endif
