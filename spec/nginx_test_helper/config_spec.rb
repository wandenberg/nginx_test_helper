require 'spec_helper'
require 'nginx_test_helper/config'

describe NginxTestHelper::Config do
  let(:configuration) { {} }
  let(:subject) { NginxTestHelper::Config.new("config_id", configuration) }

  it "should include NginxTestHelper module" do
    expect(subject.class.included_modules).to include(NginxTestHelper::EnvMethods)
  end

  it "should define some keys with configuration filename, logs and temp dirs configurations" do
    default_configuration = NginxTestHelper::Config.new("config_id", {}).configuration
    expect(default_configuration[:configuration_filename]).to eql("/tmp/nginx_tests/config_id.conf")
    expect(default_configuration[:pid_file]).to eql("/tmp/nginx_tests/nginx.pid")
    expect(default_configuration[:access_log]).to eql("/tmp/nginx_tests/logs/access-config_id.log")
    expect(default_configuration[:error_log]).to eql("/tmp/nginx_tests/logs/error-config_id.log")
    expect(default_configuration[:client_body_temp]).to eql("/tmp/nginx_tests/client_body_temp")
  end

  it "should merge 'default configuration' with configuration filename, logs and temp dirs configurations" do
    default_configuration = NginxTestHelper::Config.new("config_id", {}).configuration
    expect(default_configuration.keys).to eql([:conf_item, :configuration_filename, :pid_file, :access_log, :error_log, :client_body_temp])
  end

  it "should merge given configuration with 'default configuration', configuration filename, logs and temp dirs configurations" do
    default_configuration = NginxTestHelper::Config.new("config_id", {:custom_key => "value"}).configuration
    expect(default_configuration.keys).to eql([:conf_item, :custom_key, :configuration_filename, :pid_file, :access_log, :error_log, :client_body_temp])
  end

  it "should create dirs where logs and client_body_temp will be stored" do
    NginxTestHelper::Config.new("config_id", {})
    expect(File.exists?("/tmp/nginx_tests/logs")).to be true
    expect(File.exists?("/tmp/nginx_tests/client_body_temp")).to be true
  end

  it "should create the configuration file using the template configuration" do
    expect(File.read(subject.configuration[:configuration_filename])).to eql('"template configuration config_id"')
  end

  context "when using an alternative template" do
    let(:configuration) { {:foo => "bar", :configuration_template => %("custom template writing <%=configuration[:foo]%>")} }

    it "should create the configuration file using this template" do
      expect(File.read(subject.configuration[:configuration_filename])).to eql('"custom template writing bar"')
    end
  end

  it "should has a method to delete config and log files" do
    NginxTestHelper::Config.delete_config_and_log_files(subject.config_id)
    expect(File.exists?(subject.configuration[:configuration_filename])).to be false
    expect(File.exists?(subject.configuration[:access_log])).to be false
    expect(File.exists?(subject.configuration[:error_log])).to be false
    expect(File.exists?(subject.configuration[:client_body_temp])).to be false
  end

  it "should expose configurations keys as methods" do
    config = NginxTestHelper::Config.new("config_id", { :foo => "bar", :xyz => 1})
    expect(config.foo).to eql("bar")
    expect(config.xyz).to eql(1)
  end

  it "should raise exception if configuration key does not exists" do
    config = NginxTestHelper::Config.new("config_id", { :foo => "bar"})
    expect { config.xyz }.to raise_error(NameError, "undefined local variable, method or configuration 'xyz'")
  end

  it "should return 'true' to respond_to method for a configuration key" do
    config = NginxTestHelper::Config.new("config_id", { :foo => "bar"})
    expect(config).to respond_to("config_id")
    expect(config).to respond_to(:foo)
  end

  context "when using the write_directive helper method" do
    let(:configuration) { {:foo => "bar", :xyz => nil, :configuration_template => %(\n<%= write_directive('name', foo, 'comment foo') %>\n<%= write_directive('without_comment', foo) %>\n<%= write_directive('xyz', xyz, 'comment xyz') %>\n<%= write_directive('xyz_without_comment', xyz) %>)} }

    it "should comment the line when value is nil" do
      conf = File.read(subject.configuration[:configuration_filename])
      expect(conf).to include(%(\n#comment xyz\n#xyz "";))
      expect(conf).to include(%(\n#xyz_without_comment "";))
    end

    it "should write the line when value is not nil" do
      conf = File.read(subject.configuration[:configuration_filename])
      expect(conf).to include(%(\n#comment foo\nname "bar";))
      expect(conf).to include(%(\nwithout_comment "bar";))
    end

    context "when value is an Array" do
      let(:configuration) { {:foo => ["bar", "zzz"], :xyz => nil, :configuration_template => %(\n<%= write_directive('name', foo, 'comment foo') %>\n<%= write_directive('without_comment', foo) %>)} }

      it "should write multiple itens without quotes" do
        conf = File.read(subject.configuration[:configuration_filename])
        expect(conf).to include(%(\n#comment foo\nname bar zzz;))
        expect(conf).to include(%(\nwithout_comment bar zzz;))
      end
    end
  end
end
