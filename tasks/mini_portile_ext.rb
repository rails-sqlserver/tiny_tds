# Till this pull request is merged.
# https://github.com/luislavena/mini_portile/pull/15

require 'net/ftp'

MiniPortile.class_eval do

  private

  def download_file(url, full_path, count = 3)
    return if File.exist?(full_path)
    uri = URI.parse(url)
    begin
      case uri.scheme.downcase
      when /ftp/
        download_file_ftp(uri, full_path)
      when /http|https/
        download_file_http(url, full_path, count)
      end
    rescue Exception => e
      File.unlink full_path if File.exists?(full_path)
      output "ERROR: #{e.message}"
      raise "Failed to complete download task"
    end
  end

  # Slighly modified from RubyInstaller uri_ext, Rubinius configure
  # and adaptations of Wayne's RailsInstaller
  def download_file_http(url, full_path, count = 3)
    filename = File.basename(full_path)

    if ENV['http_proxy']
      protocol, userinfo, host, port  = URI::split(ENV['http_proxy'])
      proxy_user, proxy_pass = userinfo.split(/:/) if userinfo
      http = Net::HTTP::Proxy(host, port, proxy_user, proxy_pass)
    else
      http = Net::HTTP
    end

    message "Downloading #{filename} "
    http.get_response(URI.parse(url)) do |response|
      case response
      when Net::HTTPNotFound
        output "404 - Not Found"
        return false

      when Net::HTTPClientError
        output "Error: Client Error: #{response.inspect}"
        return false

      when Net::HTTPRedirection
        raise "Too many redirections for the original URL, halting." if count <= 0
        url = response["location"]
        return download_file(url, full_path, count - 1)

      when Net::HTTPOK
        with_tempfile(filename, full_path) do |temp_file|
          size = 0
          progress = 0
          total = response.header["Content-Length"].to_i
          response.read_body do |chunk|
            temp_file << chunk
            size += chunk.size
            new_progress = (size * 100) / total
            unless new_progress == progress
              message "\rDownloading %s (%3d%%) " % [filename, new_progress]
            end
            progress = new_progress
          end
          output
        end
      end
    end
  end

  def download_file_ftp(uri, full_path)
    filename = File.basename(uri.path)
    with_tempfile(filename, full_path) do |temp_file|
      size = 0
      progress = 0
      Net::FTP.open(uri.host, uri.user, uri.password) do |ftp|
        ftp.passive = true
        ftp.login
        remote_dir = File.dirname(uri.path)
        ftp.chdir(remote_dir) unless remote_dir == '.'
        total = ftp.size(filename)
        ftp.getbinaryfile(filename, nil, 8192) do |chunk|
          temp_file << chunk
          size += chunk.size
          new_progress = (size * 100) / total
          unless new_progress == progress
            message "\rDownloading %s (%3d%%) " % [filename, new_progress]
          end
          progress = new_progress
        end
      end
      output
    end
  end

  def with_tempfile(filename, full_path)
    temp_file = Tempfile.new("download-#{filename}")
    temp_file.binmode
    yield temp_file
    temp_file.close
    File.unlink full_path if File.exists?(full_path)
    FileUtils.mkdir_p File.dirname(full_path)
    FileUtils.mv temp_file.path, full_path, :force => true
  end

end
