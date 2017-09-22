
ICONV_VERSION = ENV['TINYTDS_ICONV_VERSION'] || "1.15"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

OPENSSL_VERSION = ENV['TINYTDS_OPENSSL_VERSION'] || '1.1.0e'
OPENSSL_SOURCE_URI = "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "1.00.27"
FREETDS_VERSION_INFO = Hash.new { |h,k|
  h[k] = {files: "http://www.freetds.org/files/stable/freetds-#{k}.tar.bz2"}
}
FREETDS_VERSION_INFO['1.00'] = {files: 'http://www.freetds.org/files/stable/freetds-1.00.tar.bz2'}
FREETDS_VERSION_INFO['0.99'] = {files: 'http://www.freetds.org/files/current/freetds-dev.0.99.678.tar.gz'}
FREETDS_VERSION_INFO['0.95'] = {files: 'http://www.freetds.org/files/stable/freetds-0.95.92.tar.gz'}
FREETDS_SOURCE_URI = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
