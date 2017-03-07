
ICONV_VERSION = ENV['TINYTDS_ICONV_VERSION'] || "1.14"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

OPENSSL_VERSION = ENV['TINYTDS_OPENSSL_VERSION'] || '1.0.2j'
OPENSSL_SOURCE_URI = "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

FREETDS_MIRROR_URI =
  'ftp://ftp.freetds.org/pub/freetds/stable/freetds-%s.tar.bz2'
# 'https://fossies.org/linux/privat/freetds-%s.tar.gz'

FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "1.00.26"
FREETDS_VERSION_INFO = Hash.new { |h,k|
  h[k] = {files: FREETDS_MIRROR_URI % [FREETDS_VERSION] }
}
FREETDS_VERSION_INFO['1.00.26'] = {files: 'https://fossies.org/linux/privat/freetds-1.00.26.tar.gz'}
FREETDS_SOURCE_URI = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
