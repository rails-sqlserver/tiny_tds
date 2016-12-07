
ICONV_VERSION = ENV['TINYTDS_ICONV_VERSION'] || "1.14"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

OPENSSL_VERSION = ENV['TINYTDS_OPENSSL_VERSION'] || '1.0.2j'
OPENSSL_SOURCE_URI = "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "1.00.21"
FREETDS_VERSION_INFO = Hash.new { |h,k|
  h[k] = {files: "ftp://ftp.freetds.org/pub/freetds/stable/freetds-#{k}.tar.bz2"}
}
FREETDS_VERSION_INFO['1.00'] = {files: 'ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.00.tar.bz2'}
FREETDS_VERSION_INFO['0.99'] = {files: 'ftp://ftp.freetds.org/pub/freetds/current/freetds-dev.0.99.678.tar.gz'}
FREETDS_VERSION_INFO['0.95'] = {files: 'ftp://ftp.freetds.org/pub/freetds/stable/freetds-0.95.92.tar.gz'}
FREETDS_SOURCE_URI = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
