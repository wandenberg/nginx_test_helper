require 'spec_helper'

class SomeClass
  include NginxTestHelper::EnvMethods
end

describe NginxTestHelper::EnvMethods do
  shared_examples_for "has nginx configuration methods" do
    context "with default values" do
      it "should return nginx executable" do
        subject.nginx_executable.should eql("/usr/local/nginx/sbin/nginx")
      end

      it "should return nginx host" do
        subject.nginx_host.should eql("127.0.0.1")
      end

      it "should return nginx port" do
        subject.nginx_port.should eql("9990")
      end

      it "should return nginx workers" do
        subject.nginx_workers.should eql("1")
      end

      it "should return nginx tests tmp dir" do
        subject.nginx_tests_tmp_dir.should eql("/tmp/nginx_tests")
      end
    end

    context "with environment values" do
      it "should return nginx executable" do
        ENV['NGINX_EXEC'] = "/path/to/nginx/executable"
        subject.nginx_executable.should eql("/path/to/nginx/executable")
      end

      it "should return nginx host" do
        ENV['NGINX_HOST'] = "some_host"
        subject.nginx_host.should eql("some_host")
      end

      it "should return nginx port" do
      ENV['NGINX_PORT'] = "some_port"
        subject.nginx_port.should eql("some_port")
      end

      it "should return nginx workers" do
        ENV['NGINX_WORKERS'] = "25"
        subject.nginx_workers.should eql("25")
      end

      it "should return nginx tests tmp dir" do
        ENV['NGINX_TESTS_TMP_DIR'] = "/path/to/tests/tmp/dir"
        subject.nginx_tests_tmp_dir.should eql("/path/to/tests/tmp/dir")
      end
    end

    it "should use nginx host and port to compose nginx address" do
      subject.stub(:nginx_host).and_return("some_host")
      subject.stub(:nginx_port).and_return("some_port")

      subject.nginx_address.should eql("http://some_host:some_port")
    end
  end

  context "when a class include the NginxTestHelper::EnvMethods module" do
    let(:subject) { SomeClass }

    it_should_behave_like "has nginx configuration methods"

    context "their object instances" do
      let(:subject) { SomeClass.new }

      it_should_behave_like "has nginx configuration methods"
    end
  end

end
