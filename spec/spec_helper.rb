# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper.rb"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.before do
    FileUtils.rm_rf("/tmp/nginx_tests")
    ENV.each_key do |key|
      ENV.delete(key) if key.start_with?("NGINX_")
    end
  end
end

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
  SimpleCov.coverage_dir 'coverage'
rescue LoadError
  # ignore simplecov in ruby < 1.9
end

def with_constants(constants, &block)
  old_verbose, $VERBOSE = $VERBOSE, nil
  saved_constants = {}
  constants.each do |constant, val|
    saved_constants[ constant ] = Object.const_get( constant )
    Object.const_set( constant, val )
  end

  begin
    block.call
  ensure
    constants.each do |constant, val|
      Object.const_set( constant, saved_constants[ constant ] )
    end
    $VERBOSE = old_verbose
  end
end

module NginxConfiguration
  def self.default_configuration
    {
      :conf_item => "conf_value"
    }
  end

  def self.template_configuration
    %("template configuration <%= config_id %>")
  end
end

class SocketMock
  attr_accessor :response1, :response2, :response3, :exception

  def initialize
    @step = 0
    @response1 = ""
    @response2 = ""
    @response3 = ""
    @exception = "just to force go out of the loop"
  end

  def print(content)
  end

  def readpartial(count)
    "HTTP 200 OK\r\n\r\nBODY"
  end

  def read_nonblock(count)
    @step += 1
    if @step == 1
      @response1
    elsif @step == 2
      @response2
    elsif @step == 3
      raise @exception unless @exception.nil?
    elsif @step == 4
      @response3
    else
      raise @exception unless @exception.nil?
    end
  end
end

class Status
  attr_accessor :exitstatus

  def initialize
    @exitstatus = 0
  end
end
