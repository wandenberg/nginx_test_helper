require 'spec_helper'
require 'nginx_test_helper'

describe NginxTestHelper do

  subject { Object.new.extend(NginxTestHelper) }

  it "should define a method with basic headers" do
    expect(subject.headers).to eql({'accept' => 'text/html'})
  end

  it "should define a method to calculate the difference in seconds of two dates" do
    expect(subject.time_diff_sec(Time.now, Time.now + 10)).to eql(10)
  end

  it "should define a method to calculate the difference in milliseconds of two dates" do
    expect(subject.time_diff_milli(Time.now, Time.now + 10)).to eql(10000)
  end

  context "when working with sockets" do
    let(:socket) { SocketMock.new }

    it "should be possible to open a socket to a host and port" do
      expect(TCPSocket).to receive(:open).with("xpto.com", 100).and_return(socket)

      expect(subject.open_socket("xpto.com", 100)).to eql(socket)
    end

    it "should be possible to do a GET in an url using the opened socket, and receive header and body response" do
      expect(socket).to receive(:print).with("GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n")

      headers, body = subject.get_in_socket("/index.html", socket)
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should be possible specify the host header value to do a GET" do
      expect(socket).to receive(:print).with("GET /index.html HTTP/1.1\r\nHost: some_host_value\r\n\r\n")

      headers, body = subject.get_in_socket("/index.html", socket, {:host_header => "some_host_value"})
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should be possible use http 1.0 to do a GET" do
      expect(socket).to receive(:print).with("GET /index.html HTTP/1.0\r\n\r\n")

      headers, body = subject.get_in_socket("/index.html", socket, {:use_http_1_0 => true})
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should pass 'wait_for' attribute to 'read_response_on_socket' method when doing a GET in a url" do
      expect(socket).to receive(:print).with("GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n")
      expect(subject).to receive(:read_response_on_socket).with(socket, "wait for")

      subject.get_in_socket("/index.html", socket, {:wait_for => "wait for"})
    end

    it "should be possible to do a POST in an url using the opened socket, and receive header and body response" do
      expect(socket).to receive(:print).with("POST /service HTTP/1.1\r\nHost: localhost\r\nContent-Length: 4\r\n\r\nBODY")

      headers, body = subject.post_in_socket("/service", "BODY", socket)
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should be possible specify the host header value to do a POST" do
      expect(socket).to receive(:print).with("POST /service HTTP/1.1\r\nHost: some_host_value\r\nContent-Length: 4\r\n\r\nBODY")

      headers, body = subject.post_in_socket("/service", "BODY", socket, {:host_header => "some_host_value"})
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should be possible use http 1.0 to do a POST" do
      expect(socket).to receive(:print).with("POST /service HTTP/1.0\r\nContent-Length: 4\r\n\r\nBODY")

      headers, body = subject.post_in_socket("/service", "BODY", socket, {:use_http_1_0 => true})
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should pass 'wait_for' attribute to 'read_response_on_socket' method when doing a POST in a url" do
      expect(socket).to receive(:print).with("POST /service HTTP/1.1\r\nHost: localhost\r\nContent-Length: 4\r\n\r\nBODY")
      expect(subject).to receive(:read_response_on_socket).with(socket, "wait for")

      headers, body = subject.post_in_socket("/service", "BODY", socket, {:wait_for => "wait for"})
    end

    it "should be possible read a response in a opened socket" do
      headers, body = subject.read_response_on_socket(socket)
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODY")
    end

    it "should concatenate response parts" do
      socket.response1 = "X"
      socket.response2 = "Y"

      headers, body = subject.read_response_on_socket(socket)
      expect(headers).to eql("HTTP 200 OK")
      expect(body).to eql("BODYXY")
    end

    it "should raise error if not receive a response" do
      allow(socket).to receive(:readpartial).and_raise(Exception)

      expect { subject.read_response_on_socket(socket) }.to raise_error("Any response")
    end

    context "and receive a Errno::EAGAIN" do
      context "and not give a text to wait for" do
        it "should return what was received until the error happens" do
          socket.response1 = "X"
          socket.response3 = "Z"
          socket.exception = Errno::EAGAIN

          headers, body = subject.read_response_on_socket(socket)
          expect(headers).to eql("HTTP 200 OK")
          expect(body).to eql("BODYX")
        end
      end

      context "and give a text to wait for" do
        it "should check if a text is present in the response" do
          socket.exception = Errno::EAGAIN

          headers, body = subject.read_response_on_socket(socket, "OD")
          expect(headers).to eql("HTTP 200 OK")
          expect(body).to eql("BODY")
        end

        it "should retry if the text is not present in the response" do
          socket.exception = Errno::EAGAIN
          socket.response3 = "Z"

          expect(IO).to receive(:select).with([socket])

          headers, body = subject.read_response_on_socket(socket, "Z")
          expect(headers).to eql("HTTP 200 OK")
          expect(body).to include("BODY")
        end
      end
    end
  end

  context "when testing configuration" do
    before do
      allow(subject).to receive(:config_id).and_return("config_id")
      allow(subject).to receive(:start_server).and_return("Server started")
      allow(subject).to receive(:stop_server).and_return("Server stoped")
    end

    it "should create an instance of NginxTestHelper::Config with the given configuation" do
      config = NginxTestHelper::Config.new("config_id", {:foo => "bar"})
      expect(NginxTestHelper::Config).to receive(:new).with("config_id", {:foo => "bar"}).and_return(config)
      subject.nginx_test_configuration({:foo => "bar"})
    end

    it "should accept test default configuration" do
      config = NginxTestHelper::Config.new("config_id", {})
      expect(NginxTestHelper::Config).to receive(:new).with("config_id", {}).and_return(config)
      subject.nginx_test_configuration
    end

    it "should call start_server and stop_server methods" do
      expect(subject).to receive(:start_server).and_return("Server started")
      expect(subject).to receive(:stop_server).and_return("Server stoped")
      subject.nginx_test_configuration({:foo => "bar"})
    end

    it "should return start command result" do
      expect(subject.nginx_test_configuration({:foo => "bar"})).to eql("Server started\n")
    end

    it "should return start command result concatenated with error log content if exists" do
      FileUtils.mkdir_p("/tmp/nginx_tests/logs/")
      File.open("/tmp/nginx_tests/logs/error-config_id.log", "w") { |f| f.write("Error log content") }
      expect(subject.nginx_test_configuration({:foo => "bar"})).to eql("Server started\nError log content")
    end
  end

  context "when starting server to make tests" do
    before do
      allow(subject).to receive(:config_id).and_return("config_id")
      allow(subject).to receive(:start_server).and_return("Server started")
      allow(subject).to receive(:stop_server).and_return("Server stoped")
    end

    it "should create an instance of NginxTestHelper::Config with the given configuation" do
      config = NginxTestHelper::Config.new("config_id", {:foo => "bar"})
      expect(NginxTestHelper::Config).to receive(:new).with("config_id", {:foo => "bar"}).and_return(config)
      subject.nginx_run_server({:foo => "bar"}) {}
    end

    it "should accept test default configuration" do
      config = NginxTestHelper::Config.new("config_id", {})
      expect(NginxTestHelper::Config).to receive(:new).with("config_id", {}).and_return(config)
      subject.nginx_run_server {}
    end

    it "should execute the block after start_server and before stop_server methods" do
      obj = {:xyz => 1}
      expect(subject).to receive(:start_server).ordered
      expect(obj).to receive(:delete).with(:xyz).ordered
      expect(subject).to receive(:stop_server).ordered

      subject.nginx_run_server({:foo => "bar"}) { obj.delete(:xyz) }
    end

    it "should execute the block inside a timeout block" do
      expect { subject.nginx_run_server({:foo => "bar"}) { sleep 6 } }.to raise_error(Timeout::Error, "execution expired")
    end

    it "should accept a custom a timeout" do
      expect { subject.nginx_run_server({:foo => "bar"}, {:timeout => 2}) { sleep 6 } }.to raise_error(Timeout::Error, "execution expired")
      expect { subject.nginx_run_server({:foo => "bar"}, {:timeout => 2}) { sleep 1 } }.to_not raise_error
    end

    it "should execute stop_server method if an exception was raised" do
      expect(subject).to receive(:stop_server)
      expect { subject.nginx_run_server({:foo => "bar"}) { raise "some error" } }.to raise_error("some error")
    end
  end

  context "when checking internal behavior" do
    before do
      allow(subject).to receive(:start_server).and_return("Server started")
      allow(subject).to receive(:stop_server).and_return("Server stoped")
      allow(subject).to receive(:example).and_return(double)
    end

    context "and check config_id value" do
      before { Thread.current[:current_example] = nil }
      after { |ex| Thread.current[:current_example] = ex }

      it "should use example metadata if available" do
        allow(subject.example).to receive(:metadata).and_return(:location => "./spec/test_config_id_spec.rb:100")
        expect(subject.send(:config_id)).to eql("test_config_id_spec_rb_100")
      end

      it "should use method_name if example metadata is not available" do
        allow(subject.example).to receive(:metadata).and_return(nil)
        allow(subject).to receive(:method_name).and_return("test_config_id_by_method_name")

        expect(subject.send(:config_id)).to eql("test_config_id_by_method_name")
      end

      it "should use __name__ if example metadata and method_name are not available" do
        allow(subject.example).to receive(:metadata).and_return(nil)
        allow(subject).to receive(:__name__).and_return("test_config_id_by___name__")

        expect(subject.send(:config_id)).to eql("test_config_id_by___name__")
      end
    end

    context "and check if the test has passed" do
      context "using example exception if available" do
        it "should be 'true' if exception is 'nil'" do
          allow(subject.example).to receive(:exception).and_return(nil)
          expect(subject.send(:has_passed?)).to be true
        end

        it "should be 'false' if exception is not 'nil'" do
          allow(subject.example).to receive(:exception).and_return("")
          expect(subject.send(:has_passed?)).to be false
        end
      end

      context "using 'test_passed' attribute if example exception is not available" do
        it "should be 'true' if 'test_passed' is 'true'" do
          subject.instance_variable_set(:@test_passed, true)
          expect(subject.send(:has_passed?)).to be true
        end

        it "should be 'false' if 'test_passed' is 'false'" do
          subject.instance_variable_set(:@test_passed, false)
          expect(subject.send(:has_passed?)).to be false
        end
      end

      context "using 'passed' attribute if example exception and 'test_passed' are not available" do
        before do
          allow(subject.example).to receive(:instance_variable_defined?).with(:@exception).and_return(false)
          subject.instance_variable_set(:@test_passed, nil)
        end

        it "should be 'true' if 'passed' is 'true'" do
          subject.instance_variable_set(:@passed, true)
          expect(subject.send(:has_passed?)).to be true
        end

        it "should be 'false' if 'passed' is 'false'" do
          subject.instance_variable_set(:@passed, false)
          expect(subject.send(:has_passed?)).to be false
        end
      end
    end
  end

  context "when starting the server" do
    let(:config) { NginxTestHelper::Config.new("config_id", {}) }
    let(:status) { Status.new }

    it "should use POpen4 to execute the command" do
      expect(POpen4).to receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf").and_return(status)
      subject.start_server(config)
    end

    it "should not start the server if configuration has a key 'disable_start_stop_server' with 'true'" do
      config.configuration[:disable_start_stop_server] = true
      expect(POpen4).not_to receive(:popen4)
      subject.start_server(config)
    end

    it "should raise error if 'exitstatus' is not '0'" do
      status.exitstatus = 1
      expect(POpen4).to receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf").and_return(status)
      expect { subject.start_server(config) }.to raise_error("Server doesn't started - ")
    end

    it "should return error message when the command fail" do
      expect(subject.start_server(config)).to eql("nginx: [emerg] unexpected end of file, expecting \";\" or \"}\" in /tmp/nginx_tests/config_id.conf:1")
    end
  end

  context "when stoping the server" do
    let(:config) { NginxTestHelper::Config.new("config_id", {}) }
    let(:status) { Status.new }

    it "should use POpen4 to execute the command" do
      expect(POpen4).to receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf -s stop").and_return(status)
      subject.stop_server(config)
    end

    it "should not start the server if configuration has a key 'disable_start_stop_server' with 'true'" do
      config.configuration[:disable_start_stop_server] = true
      expect(POpen4).not_to receive(:popen4)
      subject.stop_server(config)
    end

    it "should raise error if 'exitstatus' is not '0'" do
      status.exitstatus = 1
      expect(POpen4).to receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf -s stop").and_return(status)
      expect { subject.stop_server(config) }.to raise_error("Server doesn't stoped - ")
    end

    it "should return error message when the command fail" do
      expect(subject.stop_server(config)).to eql("nginx: [emerg] unexpected end of file, expecting \";\" or \"}\" in /tmp/nginx_tests/config_id.conf:1")
    end
  end

end
