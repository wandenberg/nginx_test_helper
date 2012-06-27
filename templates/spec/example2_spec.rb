require File.expand_path('spec_helper', File.dirname(__FILE__))
require "net/http"
require "uri"

describe "Example2 Spec" do
  before(:all) do
    configuration = {:return_code => 301} # Your configuration hash
    @config = NginxTestHelper::Config.new("example_config_id", configuration)
    start_server(@config)
  end

  after(:all) do
    stop_server(@config)
  end

  context "when using running many tests with same configuration" do
    it "should get '301' return code getting index.html" do
      uri = URI.parse("http://#{nginx_host}:#{nginx_port}/")
      response = Net::HTTP.get_response(uri)
      response.code.should eql("301")
    end

    it "should get '302' return code getting /test/index.html" do
      uri = URI.parse("http://#{nginx_host}:#{nginx_port}/test/index.html")
      response = Net::HTTP.get_response(uri)
      response.code.should eql("302")
    end
  end
end
