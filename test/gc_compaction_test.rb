require "test_helper"
require "open3"
require "rbconfig"

class GcCompactionTest < Minitest::Spec
  describe "after GC compaction" do
    it "raises TinyTds::Error instead of crashing when a connection fails" do
      skip "GC compaction is not supported on this platform" if !GC.respond_to?(:verify_compaction_references)

      # Ruby 3.2 renamed the double_heap: keyword to expand_heap:
      heap_keyword =
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2")
          "expand_heap"
        else
          "double_heap"
        end

      script = <<~RUBY
        require "tiny_tds"

        GC.verify_compaction_references(#{heap_keyword}: true, toward: :empty)

        begin
          TinyTds::Client.new(host: "127.0.0.1", port: 1, username: "unused", password: "unused", login_timeout: 1)
        rescue TinyTds::Error
          exit 0
        end

        exit 1
      RUBY

      output, status = Open3.capture2e(RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-e", script)

      assert status.success?, "expected TinyTds::Error to be raised, got #{status.inspect}:\n#{output}"
    end
  end
end
