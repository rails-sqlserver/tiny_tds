require "test_helper"
require "json"
require "open3"
require "rbconfig"

class LoginTest < Minitest::Spec
  describe "SQL Server login without the GVL" do
    it "releases the login mutex after interruption" do
      result = login_probe("interrupt")
      assert_equal "TinyTds::Error", result.fetch("next_error")
    end

    it "allows threads and GC to run while preserving overlapping login errors and timeouts" do
      result = login_probe("concurrent")
      assert_operator result.fetch("accepted_after"), :<, result.fetch("elapsed") / 2,
        "another Ruby thread could not run until login timed out"
      assert_equal [["error", 20003, 6], ["error", 20003, 6]], result.fetch("errors")
      result.fetch("durations").zip([3, 1]).each do |duration, timeout|
        assert_operator duration, :>=, timeout - 0.5
        assert_operator duration, :<, timeout + 2
      end
    end

    it "preserves server errors without delivering previously ignored login messages" do
      result = login_probe("callback")
      assert_empty result.fetch("messages")
      assert_equal ["message", 18456, 14], result.fetch("first_error")
      assert_equal ["message", 18456, 14], result.fetch("next_error")
    end
  end

  def login_probe(scenario)
    script = File.expand_path("support/login_probe.rb", __dir__)
    lib = File.expand_path("../lib", __dir__)
    Open3.popen2e(RbConfig.ruby, "-I", lib, script, scenario) do |stdin, stdout, process|
      stdin.close
      reader = Thread.new { stdout.read }
      begin
        assert process.join(20), "#{scenario} login probe exceeded its 20-second deadline"
        output = reader.value
        assert process.value.success?, "#{scenario} login probe failed:\n#{output}"
        JSON.parse(output)
      ensure
        if process.alive?
          Process.kill("KILL", process.pid)
          process.join(5)
        end
        reader.kill
        reader.join(1)
      end
    end
  end
end
