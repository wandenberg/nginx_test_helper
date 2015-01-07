require 'spec_helper'

class SomeClass
  include NginxTestHelper::EnvMethods
end

describe NginxTestHelper::EnvMethods do
  shared_examples_for "has nginx configuration methods" do
    context "with default values" do
      it "should return nginx executable" do
        expect(subject.nginx_executable).to eql("/usr/local/nginx/sbin/nginx")
      end

      it "should return nginx host" do
        expect(subject.nginx_host).to eql("127.0.0.1")
      end

      it "should return nginx port" do
        expect(subject.nginx_port).to eql("9990")
      end

      it "should return nginx workers" do
        expect(subject.nginx_workers).to eql("1")
      end

      it "should return nginx tests tmp dir" do
        expect(subject.nginx_tests_tmp_dir).to eql("/tmp/nginx_tests")
      end

      it "should return nginx tests cores dir based on tmp dir" do
        expect(subject.nginx_tests_cores_dir).to eql("/tmp/nginx_tests/cores")
      end

      it "should return nginx tests core dir based on tmp dir" do
        expect(subject.nginx_tests_core_dir("test_id")).to eql("/tmp/nginx_tests/cores/test_id")
      end
    end

    context "with environment values" do
      it "should return nginx executable" do
        ENV['NGINX_EXEC'] = "/path/to/nginx/executable"
        expect(subject.nginx_executable).to eql("/path/to/nginx/executable")
      end

      it "should return nginx host" do
        ENV['NGINX_HOST'] = "some_host"
        expect(subject.nginx_host).to eql("some_host")
      end

      it "should return nginx port" do
      ENV['NGINX_PORT'] = "some_port"
        expect(subject.nginx_port).to eql("some_port")
      end

      it "should return nginx workers" do
        ENV['NGINX_WORKERS'] = "25"
        expect(subject.nginx_workers).to eql("25")
      end

      it "should return nginx tests tmp dir" do
        ENV['NGINX_TESTS_TMP_DIR'] = "/path/to/tests/tmp/dir"
        expect(subject.nginx_tests_tmp_dir).to eql("/path/to/tests/tmp/dir")
      end

      it "should return nginx tests cores dir based on tmp dir" do
        ENV['NGINX_TESTS_TMP_DIR'] = "/path/to/tests/tmp/dir"
        expect(subject.nginx_tests_cores_dir).to eql("/path/to/tests/tmp/dir/cores")
      end

      it "should return nginx tests core dir based on tmp dir" do
        ENV['NGINX_TESTS_TMP_DIR'] = "/path/to/tests/tmp/dir"
        expect(subject.nginx_tests_core_dir("test_id")).to eql("/path/to/tests/tmp/dir/cores/test_id")
      end
    end

    it "should use nginx host and port to compose nginx address" do
      allow(subject).to receive(:nginx_host).and_return("some_host")
      allow(subject).to receive(:nginx_port).and_return("some_port")

      expect(subject.nginx_address).to eql("http://some_host:some_port")
    end

    context "when on a Darwin ruby platform" do
      it "should return kqueue as event type" do
        with_constants({"RUBY_PLATFORM" => "x86_64-darwin13.0"}) do
          expect(subject.nginx_event_type).to eql("kqueue")
        end
      end
    end

    context "when not on a Darwin ruby platform" do
      it "should return epoll as event type" do
        with_constants({"RUBY_PLATFORM" => "Any other platform"}) do
          expect(subject.nginx_event_type).to eql("epoll")
        end
      end
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
