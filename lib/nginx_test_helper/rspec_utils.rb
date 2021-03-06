if defined?(RSpec)
  require 'nginx_test_helper/http_matchers'

  RSpec.configure do |config|
    config.include NginxTestHelper
    config.include NginxTestHelper::HttpMatchers

    config.before(:suite) do
      FileUtils.rm_rf Dir[File.join(NginxTestHelper.nginx_tests_cores_dir, "**")]
    end

    config.around(:each) do |ex|
      Thread.current[:current_example] = ex
      logs = Dir[File.join(NginxTestHelper.nginx_tests_tmp_dir, "logs", "**")]
      error_log_pre = logs.map{|log| File.readlines(log)}.flatten

      ex.run

      logs = Dir[File.join(NginxTestHelper.nginx_tests_tmp_dir, "logs", "**")]
      error_log_pos = logs.map{|log| File.readlines(log)}.flatten
      raise StandardError.new("\n\n#{config_id} let open sockets\n\n") if (error_log_pos - error_log_pre).join.include?("open socket")

      cores = Dir[File.join(NginxTestHelper.nginx_tests_core_dir(config_id), "*core*")]
      raise StandardError.new("Generated core dump(s) at:\n#{cores.join("\n")}\n\n") unless cores.empty?
    end
  end

  RSpec::Matchers.define :be_in_the_interval do |min, max|
    match do |actual|
      (actual >= min) && (actual <= max)
    end

    if RSpec::Core::Version::STRING < "3.0.0"
      failure_message_for_should do |actual|
        "expected that #{actual} would be in the interval from #{min} to #{max}"
      end

      failure_message_for_should_not do |actual|
        "expected that #{actual} would not be in the interval from #{min} to #{max}"
      end
    else
      failure_message do |actual|
        "expected that #{actual} would be in the interval from #{min} to #{max}"
      end

      failure_message_when_negated do |actual|
        "expected that #{actual} would not be in the interval from #{min} to #{max}"
      end
    end

    description do
      "be in the interval from #{min} to #{max}"
    end
  end

  RSpec::Matchers.define :match_the_pattern do |pattern|
    match do |actual|
      actual.match(pattern)
    end

    if RSpec::Core::Version::STRING < "3.0.0"
      failure_message_for_should do |actual|
        "expected that '#{actual}' would match the pattern '#{pattern.inspect}'"
      end

      failure_message_for_should_not do |actual|
        "expected that '#{actual}' would not match the pattern '#{pattern.inspect}'"
      end
    else
      failure_message do |actual|
        "expected that '#{actual}' would match the pattern '#{pattern.inspect}'"
      end

      failure_message_when_negated do |actual|
        "expected that '#{actual}' would not match the pattern '#{pattern.inspect}'"
      end
    end

    description do
      "match the pattern '#{pattern.inspect}'"
    end
  end
end
