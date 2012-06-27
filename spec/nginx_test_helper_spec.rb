require 'spec_helper'

describe NginxTestHelper do
  include NginxTestHelper

  it "should define a method with basic headers" do
    headers.should eql({'accept' => 'text/html'})
  end

  it "should define a method to calculate the difference in seconds of two dates" do
    time_diff_sec(Time.now, Time.now + 10).should eql(10)
  end

  it "should define a method to calculate the difference in milliseconds of two dates" do
    time_diff_milli(Time.now, Time.now + 10).should eql(10000)
  end

  context "when working with sockets" do
    let(:socket) { SocketMock.new }

    it "should be possible to open a socket to a host and port" do
      TCPSocket.should_receive(:open).with("xpto.com", 100).and_return(socket)

      open_socket("xpto.com", 100).should eql(socket)
    end

    it "should be possible to do a GET in an url using the opened socket, and receive header and body response" do
      socket.should_receive(:print).with("GET /index.html HTTP/1.0\r\n\r\n")

      headers, body = get_in_socket("/index.html", socket)
      headers.should eql("HTTP 200 OK")
      body.should eql("BODY")
    end

    it "should pass 'wait_for' attribute to 'read_response_on_socket' method when doing a GET in a url" do
      socket.should_receive(:print).with("GET /index.html HTTP/1.0\r\n\r\n")
      self.should_receive(:read_response_on_socket).with(socket, "wait for")

      get_in_socket("/index.html", socket, "wait for")
    end

    it "should be possible to do a POST in an url using the opened socket, and receive header and body response" do
      socket.should_receive(:print).with("POST /service HTTP/1.0\r\nContent-Length: 4\r\n\r\nBODY")

      headers, body = post_in_socket("/service", "BODY", socket)
      headers.should eql("HTTP 200 OK")
      body.should eql("BODY")
    end

    it "should pass 'wait_for' attribute to 'read_response_on_socket' method when doing a POST in a url" do
      socket.should_receive(:print).with("POST /service HTTP/1.0\r\nContent-Length: 4\r\n\r\nBODY")
      self.should_receive(:read_response_on_socket).with(socket, "wait for")

      headers, body = post_in_socket("/service", "BODY", socket, "wait for")
    end

    it "should be possible read a response in a opened socket" do
      headers, body = read_response_on_socket(socket)
      headers.should eql("HTTP 200 OK")
      body.should eql("BODY")
    end

    it "should concatenate response parts" do
      socket.response1 = "X"
      socket.response2 = "Y"

      headers, body = read_response_on_socket(socket)
      headers.should eql("HTTP 200 OK")
      body.should eql("BODYXY")
    end

    it "should raise error if not receive a response" do
      socket.stub!(:readpartial).and_raise(Exception)

      expect { read_response_on_socket(socket) }.to raise_error("Any response")
    end

    context "and receive a Errno::EAGAIN" do
      context "and not give a text to wait for" do
        it "should return what was received until the error happens" do
          socket.response1 = "X"
          socket.response3 = "Z"
          socket.exception = Errno::EAGAIN

          headers, body = read_response_on_socket(socket)
          headers.should eql("HTTP 200 OK")
          body.should eql("BODYX")
        end
      end

      context "and give a text to wait for" do
        it "should check if a text is present in the response" do
          socket.exception = Errno::EAGAIN

          headers, body = read_response_on_socket(socket, "OD")
          headers.should eql("HTTP 200 OK")
          body.should eql("BODY")
        end

        it "should retry if the text is not present in the response" do
          socket.exception = Errno::EAGAIN
          socket.response3 = "Z"

          IO.should_receive(:select).with([socket]).any_number_of_times

          headers, body = read_response_on_socket(socket, "Z")
          headers.should eql("HTTP 200 OK")
          body.should include("BODY")
        end
      end
    end
  end

  context "when testing configuration" do
    before do
      self.stub!(:config_id).and_return("config_id")
      self.stub!(:start_server).and_return("Server started")
      self.stub!(:stop_server).and_return("Server stoped")
    end

    it "should create an instance of NginxTestHelper::Config with the given configuation" do
      config = NginxTestHelper::Config.new("config_id", {:foo => "bar"})
      NginxTestHelper::Config.should_receive(:new).with("config_id", {:foo => "bar"}).and_return(config)
      nginx_test_configuration({:foo => "bar"})
    end

    it "should accept test default configuration" do
      config = NginxTestHelper::Config.new("config_id", {})
      NginxTestHelper::Config.should_receive(:new).with("config_id", {}).and_return(config)
      nginx_test_configuration
    end

    it "should call start_server and stop_server methods" do
      self.should_receive(:start_server).and_return("Server started")
      self.should_receive(:stop_server).and_return("Server stoped")
      nginx_test_configuration({:foo => "bar"})
    end

    it "should return start command result" do
      nginx_test_configuration({:foo => "bar"}).should eql("Server started\n")
    end

    it "should return start command result concatenated with error log content if exists" do
      FileUtils.mkdir_p("/tmp/nginx_tests/logs/")
      File.open("/tmp/nginx_tests/logs/error-config_id.log", "w") { |f| f.write("Error log content") }
      nginx_test_configuration({:foo => "bar"}).should eql("Server started\nError log content")
    end
  end

  context "when starting server to make tests" do
    before do
      self.stub!(:config_id).and_return("config_id")
      self.stub!(:start_server).and_return("Server started")
      self.stub!(:stop_server).and_return("Server stoped")
    end

    it "should create an instance of NginxTestHelper::Config with the given configuation" do
      config = NginxTestHelper::Config.new("config_id", {:foo => "bar"})
      NginxTestHelper::Config.should_receive(:new).with("config_id", {:foo => "bar"}).and_return(config)
      nginx_run_server({:foo => "bar"}) {}
    end

    it "should accept test default configuration" do
      config = NginxTestHelper::Config.new("config_id", {})
      NginxTestHelper::Config.should_receive(:new).with("config_id", {}).and_return(config)
      nginx_run_server {}
    end

    it "should execute the block after start_server and before stop_server methods" do
      obj = {:xyz => 1}
      self.should_receive(:start_server).ordered
      obj.should_receive(:delete).with(:xyz).ordered
      self.should_receive(:stop_server).ordered

      nginx_run_server({:foo => "bar"}) { obj.delete(:xyz) }
    end

    it "should execute the block inside a timeout block" do
      expect { nginx_run_server({:foo => "bar"}) { sleep 6 } }.to raise_error(Timeout::Error, "execution expired")
    end

    it "should accept a custom a timeout" do
      expect { nginx_run_server({:foo => "bar"}, {:timeout => 2}) { sleep 6 } }.to raise_error(Timeout::Error, "execution expired")
      expect { nginx_run_server({:foo => "bar"}, {:timeout => 2}) { sleep 1 } }.to_not raise_error(Timeout::Error, "execution expired")
    end

    it "should execute stop_server method if an exception was raised" do
      self.should_receive(:stop_server)
      expect { nginx_run_server({:foo => "bar"}) { raise "some error" } }.to raise_error("some error")
    end
  end

  context "when checking internal behavior" do
    before do
      self.stub!(:start_server).and_return("Server started")
      self.stub!(:stop_server).and_return("Server stoped")
    end

    context "and check config_id value" do
      it "should use example metadata if available" do
        self.example.stub!(:metadata).and_return(:location => "./spec/test_config_id_spec.rb:100")
        self.send(:config_id).should eql("test_config_id_spec_rb_100")
      end

      it "should use method_name if example metadata is not available" do
        self.example.stub!(:metadata).and_return(nil)
        def method_name
          "test_config_id_by_method_name"
        end
        self.send(:config_id).should eql("test_config_id_by_method_name")
      end

      it "should use __name__ if example metadata and method_name are not available" do
        self.example.stub!(:metadata).and_return(nil)
        def __name__
          "test_config_id_by___name__"
        end
        self.send(:config_id).should eql("test_config_id_by___name__")
      end
    end

    context "and check if the test has passed" do
      context "using example exception if available" do
        it "should be 'true' if exception is 'nil'" do
          self.example.stub!(:exception).and_return(nil)
          self.send(:has_passed?).should be_true
        end

        it "should be 'false' if exception is not 'nil'" do
          self.example.stub!(:exception).and_return("")
          self.send(:has_passed?).should be_false
        end
      end

      context "using 'test_passed' attribute if example exception is not available" do
        before { self.example.stub!(:instance_variable_defined?).with(:@exception).and_return(false) }

        it "should be 'true' if 'test_passed' is 'true'" do
          self.instance_variable_set(:@test_passed, true)
          self.send(:has_passed?).should be_true
        end

        it "should be 'false' if 'test_passed' is 'false'" do
          self.instance_variable_set(:@test_passed, false)
          self.send(:has_passed?).should be_false
        end
      end

      context "using 'passed' attribute if example exception and 'test_passed' are not available" do
        before do
          self.example.stub!(:instance_variable_defined?).with(:@exception).and_return(false)
          self.instance_variable_set(:@test_passed, nil)
        end

        it "should be 'true' if 'passed' is 'true'" do
          self.instance_variable_set(:@passed, true)
          self.send(:has_passed?).should be_true
        end

        it "should be 'false' if 'passed' is 'false'" do
          self.instance_variable_set(:@passed, false)
          self.send(:has_passed?).should be_false
        end
      end
    end
  end

  context "when starting the server" do
    let(:config) { NginxTestHelper::Config.new("config_id", {}) }
    let(:status) { Status.new }

    it "should use POpen4 to execute the command" do
      POpen4.should_receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf").and_return(status)
      start_server(config)
    end

    it "should not start the server if configuration has a key 'disable_start_stop_server' with 'true'" do
      config.configuration[:disable_start_stop_server] = true
      POpen4.should_not_receive(:popen4)
      start_server(config)
    end

    it "should raise error if 'exitstatus' is not '0'" do
      status.exitstatus = 1
      POpen4.should_receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf").and_return(status)
      expect { start_server(config) }.to raise_error("Server doesn't started - ")
    end

    it "should return error message when the command fail" do
      start_server(config).should eql("nginx: [emerg] unexpected end of file, expecting \";\" or \"}\" in /tmp/nginx_tests/config_id.conf:1")
    end
  end

  context "when stoping the server" do
    let(:config) { NginxTestHelper::Config.new("config_id", {}) }
    let(:status) { Status.new }

    it "should use POpen4 to execute the command" do
      POpen4.should_receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf -s stop").and_return(status)
      stop_server(config)
    end

    it "should not start the server if configuration has a key 'disable_start_stop_server' with 'true'" do
      config.configuration[:disable_start_stop_server] = true
      POpen4.should_not_receive(:popen4)
      stop_server(config)
    end

    it "should raise error if 'exitstatus' is not '0'" do
      status.exitstatus = 1
      POpen4.should_receive(:popen4).with("/usr/local/nginx/sbin/nginx -c /tmp/nginx_tests/config_id.conf -s stop").and_return(status)
      expect { stop_server(config) }.to raise_error("Server doesn't stoped - ")
    end

    it "should return error message when the command fail" do
      stop_server(config).should eql("nginx: [emerg] unexpected end of file, expecting \";\" or \"}\" in /tmp/nginx_tests/config_id.conf:1")
    end
  end

end
