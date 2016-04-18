
ICONV_VERSION = ENV['TINYTDS_ICONV_VERSION'] || "1.14"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

OPENSSL_VERSION = ENV['TINYTDS_OPENSSL_VERSION'] || '1.0.2g'
OPENSSL_SOURCE_URI = "http://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "1.0rc1"
FREETDS_VERSION_INFO = Hash.new { |h,k|
  h[k] = {files: "ftp://ftp.freetds.org/pub/freetds/stable/freetds-#{k}.tar.bz2"}
}
FREETDS_VERSION_INFO['1.0rc1'] = {files: 'ftp://ftp.freetds.org/pub/freetds/stable/release_candidates/freetds-1.0rc1.tar.bz2'}
FREETDS_VERSION_INFO['0.99'] = {files: 'ftp://ftp.freetds.org/pub/freetds/current/freetds-dev.0.99.678.tar.gz'}
FREETDS_VERSION_INFO['0.95'] = {files: 'ftp://ftp.freetds.org/pub/freetds/stable/freetds-0.95.92.tar.gz'}
FREETDS_SOURCE_URI = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
