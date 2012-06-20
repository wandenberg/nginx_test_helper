require File.expand_path('spec_helper', File.dirname(__FILE__))
require "net/http"
require "uri"

describe "Example Spec" do
  context "when using 'nginx_test_configuration' helper" do
    it "should not accept an 'unknown_directive'" do
      nginx_test_configuration({:unknown_value => 0}).should include('unknown directive "unknown_directive"')
    end
  end

  context "when using 'nginx_run_server' helper" do
    it "should get '202' return code using 'get_in_socket' helper" do
      nginx_run_server do
        socket = open_socket(nginx_host, nginx_port)
        headers, body = get_in_socket("/index.html", socket)
        headers.should include("HTTP/1.1 202 Accepted")
      end
    end

    it "should get '422' return code using 'Net/Http'" do
      nginx_run_server({:return_code => 422}) do
        uri = URI.parse("http://#{nginx_host}:#{nginx_port}/")
        response = Net::HTTP.get_response(uri)
        response.code.should eql("422")
      end
    end

    it "should use custom timeout" do
      expect do
        nginx_run_server({}, {:timeout => 1}) do
          sleep 2
        end
      end.to raise_error(Timeout::Error, "execution expired")
    end
  end
end
