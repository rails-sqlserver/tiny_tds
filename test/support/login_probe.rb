require "tiny_tds"
require "socket"
require "json"

def clock
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

def connect(port, timeout, options = {})
  TinyTds::Client.new(host: "127.0.0.1", port: port,
    username: "unused", password: "unused", login_timeout: timeout, **options)
end

def login_error
  yield
  raise "expected login to fail"
rescue TinyTds::Error => error
  [error.source, error.db_error_number, error.severity]
end

def read_packet(peer)
  header = peer.read(8)
  raise "missing TDS packet header" unless header && header.bytesize == 8
  peer.read(header.unpack("CCn").last - 8)
end

def write_packet(peer, payload)
  peer.write([4, 1, payload.bytesize + 8, 0, 1, 0].pack("CCnnCC") + payload)
end

def login_message(token, number, severity, text)
  message = text.encode("UTF-16LE").b
  body = [number, 1, severity, message.bytesize / 2].pack("VCCv") + message + [0, 0, 1].pack("CCV")
  [token, body.bytesize].pack("Cv") + body
end

server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]
result = case ARGV.fetch(0)
when "interrupt"
  connector = Thread.new { connect(port, 2) }
  peer = server.accept
  connector.kill
  connector.join
  peer.close
  server.close
  begin
    connect(port, 1)
    raise "expected subsequent login to fail"
  rescue TinyTds::Error => error
    {next_error: error.class.name}
  end
when "concurrent"
  accepted = Queue.new
  durations = []
  listener = Thread.new do
    2.times do
      peer = server.accept
      accepted_at = clock
      accepted << accepted_at
      peer.read
      durations << clock - accepted_at
      peer.close
    end
  end
  started = clock
  first = Thread.new do
    error = login_error { connect(port, 3) }
    [error, clock - started]
  end
  accepted_after = accepted.pop - started
  GC.start
  GC.compact if GC.respond_to?(:compact)
  second = Thread.new { login_error { connect(port, 1) } }
  first_error, elapsed = first.value
  errors = [first_error, second.value]
  listener.value
  {errors: errors, durations: durations, elapsed: elapsed, accepted_after: accepted_after}
when "callback"
  listener = Thread.new do
    2.times do
      peer = server.accept
      read_packet(peer)
      # PRELOGIN: version and encryption-not-supported, followed by LOGIN7.
      write_packet(peer, [0, 11, 6, 1, 17, 1, 255].pack("CnnCnnC") + "\x0f\x00\x00\x00\x00\x00\x02".b)
      read_packet(peer)
      info = login_message(0xab, 5701, 10, "Login information")
      error = login_message(0xaa, 18456, 14, "Login failed for user")
      done = [0xfd, 2, 0, 0].pack("CvvQ<")
      write_packet(peer, info + error + done)
      peer.close
    end
  end
  messages = []
  first_error = login_error do
    connect(port, 2, message_handler: proc { |message|
      messages << message.message
      raise "unexpected login callback"
    })
  end
  next_error = login_error { connect(port, 2) }
  listener.value
  {messages: messages, first_error: first_error, next_error: next_error}
else
  raise "unknown login probe"
end

puts JSON.generate(result)
