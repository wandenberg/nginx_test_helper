require 'spec_helper'

describe NginxTestHelper::CommandLineTool do
  before do
    $stdout.stub!(:puts)
    Dir.stub!(:pwd).and_return('tmp')
    FileUtils.mkdir_p('tmp/spec')
  end

  after do
    FileUtils.rm_rf('tmp')
  end

  it "should list available options" do
    $stdout.should_receive(:puts).with(/init/)
    $stdout.should_receive(:puts).with(/license/)
    NginxTestHelper::CommandLineTool.new.process []
  end

  it "should list the gem license" do
    $stdout.should_receive(:puts).with(/MIT License/)
    NginxTestHelper::CommandLineTool.new.process ["license"]
  end

  it "should create example files showing how to use the gem" do
    NginxTestHelper::CommandLineTool.new.process ["init"]
    File.exists?('tmp/spec/nginx_configuration.rb').should be_true
    File.exists?('tmp/spec/example_spec.rb').should be_true
    File.exists?('tmp/spec/spec_helper.rb').should be_true

    File.read('tmp/spec/nginx_configuration.rb').should eql(File.read('templates/spec/nginx_configuration.rb'))
    File.read('tmp/spec/example_spec.rb').should eql(File.read('templates/spec/example_spec.rb'))
    File.read('tmp/spec/spec_helper.rb').should include('nginx_configuration')
  end

  it "should include require call on spec_helper if NgincConfiguration is not defined" do
    Object.stub!(:const_defined?).with('NginxConfiguration').and_return(false)
    File.open('tmp/spec/spec_helper.rb', 'w') { |f| f.write("#spec_helper content") }
    NginxTestHelper::CommandLineTool.new.process ["init"]
    File.read('tmp/spec/spec_helper.rb').should eql("#spec_helper content\nrequire File.expand_path('nginx_configuration', File.dirname(__FILE__))")
  end

  it "should print INSTALL file content" do
    $stdout.should_receive(:puts).with(/Nginx Test Helper has been installed with example specs./)
    NginxTestHelper::CommandLineTool.new.process ["init"]
  end
end
