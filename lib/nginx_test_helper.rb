require "nginx_test_helper/version"
require "nginx_test_helper/env_methods"
require "nginx_test_helper/config"
require "nginx_test_helper/http_matchers"
require "nginx_test_helper/rspec_utils"
require "nginx_test_helper/command_line_tool"
require "popen4"
require "timeout"
require "socket"

module NginxTestHelper
  include NginxTestHelper::EnvMethods

  def nginx_run_server(configuration={}, options={}, &block)
    config = Config.new(config_id, configuration)
    start_server(config)
    Timeout::timeout(options[:timeout] || 5) do
      block.call(config)
    end
  ensure
    stop_server(config) unless config.nil?
  end

  def nginx_test_configuration(configuration={})
    config = Config.new(config_id, configuration)
    stderr_msg = start_server(config)
    stop_server(config)
    "#{stderr_msg}\n#{File.read(config.error_log) if File.exists?(config.error_log)}"
  end

  def open_socket(host, port)
    TCPSocket.open(host, port)
  end

  def get_in_socket(url, socket, options={})
    options = {:use_http_1_0 => false, :host_header => "localhost"}.merge(options)
    socket.print("GET #{url} HTTP/1.#{options[:use_http_1_0] ? "0" : "1\r\nHost: #{options[:host_header]}"}\r\n\r\n")
    read_response_on_socket(socket, options[:wait_for])
  end

  def post_in_socket(url, body, socket, options={})
    options = {:use_http_1_0 => false, :host_header => "localhost"}.merge(options)
    socket.print("POST #{url} HTTP/1.#{options[:use_http_1_0] ? "0" : "1\r\nHost: #{options[:host_header]}"}\r\nContent-Length: #{body.size}\r\n\r\n#{body}")
    read_response_on_socket(socket, options[:wait_for])
  end

  def read_response_on_socket(socket, wait_for=nil)
    will_retry = false
    response ||= socket.readpartial(1)
    while (tmp = socket.read_nonblock(256))
      response += tmp
    end
  rescue Errno::EAGAIN => e
    unless(wait_for.nil? || response.include?(wait_for))
      will_retry = true
      IO.select([socket])
      retry
    end
  ensure
    unless will_retry
      fail("Any response") if response.nil?
      headers, body = response.split("\r\n\r\n", 2)
      return headers, body
    end
  end

  def time_diff_milli(start, finish)
     ((finish - start) * 1000.0).to_i
  end

  def time_diff_sec(start, finish)
     (finish - start).to_i
  end

  def headers
    {'accept' => 'text/html'}
  end

  def start_server(config)
    error_message = ""
    unless config.configuration[:disable_start_stop_server]
      working_dir = nginx_tests_core_dir(config.config_id)
      FileUtils.mkdir_p working_dir
      Dir.chdir working_dir do
        status = POpen4::popen4("#{ config.nginx_executable } -c #{ config.configuration_filename }") do |stdout, stderr, stdin, pid|
          error_message = stderr.read.strip unless stderr.eof
          return error_message unless error_message.nil?
        end
        fail("Server doesn't started - #{error_message}") unless status.exitstatus == 0
      end
    end
    error_message
  end

  def stop_server(config)
    error_message = ""
    unless config.configuration[:disable_start_stop_server]
      status = POpen4::popen4("#{ config.nginx_executable } -c #{ config.configuration_filename } -s stop") do |stdout, stderr, stdin, pid|
        error_message = stderr.read.strip unless stderr.eof
        return error_message unless error_message.nil?
      end
      fail("Server doesn't stoped - #{error_message}") unless status.exitstatus == 0
    end
    error_message
  end

private
  def config_id
    if self.respond_to?(:example) && !self.example.nil? &&
       self.example.respond_to?(:metadata) && !self.example.metadata.nil? &&
       !self.example.metadata[:location].nil?
      (self.example.metadata[:location].split('/') - [".", "spec"]).join('_').gsub(/[\.\:]/, '_')
    elsif self.respond_to?('method_name')
      self.method_name
    else
      self.__name__
    end
  end

  def has_passed?
    if self.respond_to?(:example) && !self.example.nil? && self.example.instance_variable_defined?(:@exception)
      self.example.exception.nil?
    elsif !@test_passed.nil?
      @test_passed
    else
      @passed
    end
  end
end
