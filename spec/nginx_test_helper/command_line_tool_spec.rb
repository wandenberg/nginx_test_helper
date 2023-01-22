require 'spec_helper'
require 'nginx_test_helper/command_line_tool'

describe NginxTestHelper::CommandLineTool do
  before do
    allow($stdout).to receive(:puts)
    allow(Dir).to receive(:pwd).and_return('tmp')
    FileUtils.mkdir_p('tmp/spec')
  end

  after do
    FileUtils.rm_rf('tmp')
  end

  it "should list available options" do
    expect($stdout).to receive(:puts).with(/init/)
    expect($stdout).to receive(:puts).with(/license/)
    NginxTestHelper::CommandLineTool.new.process []
  end

  it "should list the gem license" do
    expect($stdout).to receive(:puts).with(/MIT License/)
    NginxTestHelper::CommandLineTool.new.process ["license"]
  end

  it "should create example files showing how to use the gem" do
    NginxTestHelper::CommandLineTool.new.process ["init"]
    expect(File.exist?('tmp/spec/nginx_configuration.rb')).to be true
    expect(File.exist?('tmp/spec/example_spec.rb')).to be true
    expect(File.exist?('tmp/spec/spec_helper.rb')).to be true

    expect(File.read('tmp/spec/nginx_configuration.rb')).to eql(File.read('templates/spec/nginx_configuration.rb'))
    expect(File.read('tmp/spec/example_spec.rb')).to eql(File.read('templates/spec/example_spec.rb'))
    expect(File.read('tmp/spec/spec_helper.rb')).to include('nginx_configuration')
  end

  it "should include require call on spec_helper if NgincConfiguration is not defined" do
    allow(Object).to receive(:const_defined?).with('NginxConfiguration').and_return(false)
    File.open('tmp/spec/spec_helper.rb', 'w') { |f| f.write("#spec_helper content") }
    NginxTestHelper::CommandLineTool.new.process ["init"]
    expect(File.read('tmp/spec/spec_helper.rb')).to eql("#spec_helper content\nrequire File.expand_path('nginx_configuration', File.dirname(__FILE__))")
  end

  it "should print INSTALL file content" do
    expect($stdout).to receive(:puts).with(/Nginx Test Helper has been installed with example specs./)
    NginxTestHelper::CommandLineTool.new.process ["init"]
  end
end
