# NginxTestHelper

A collection of helper methods to test your nginx module.

## Installation

Add this line to your application's Gemfile:

    gem 'nginx_test_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nginx_test_helper

## Usage

Create a module called NginxConfiguration with two class methods:
`default_configuration`, which should return a hash with the default configuration values, and `template_configuration` which should return the Nginx configuration template.

You can use the command bellow to generate this file

    $ nginx_test_helper init

The init command also create a example_spec.rb to show how to use the main methods:

### nginx_test_configuration

Starts the server with the given configuration and template, stop it and return the `stderr` and `error log` to be possible to check some condition.

    nginx_test_configuration({:unknown_value => 0}).should include('unknown directive "unknown_directive"')

### nginx_run_server

Starts the server, execute the given block inside a `Timeout block` and stop the server.

    nginx_run_server({:return_code => 422}) do
      uri = URI.parse("http://#{nginx_host}:#{nginx_port}/")
      response = Net::HTTP.get_response(uri)
      response.code.should eql("422")
    end

You can customize the timeout value, default 5 seconds, using the second parameter of `nginx_run_server` method.

    nginx_run_server({}, {:timeout => 1}) do
      sleep 2
    end

### start_server / stop_server

If you want to start the server and run many test cases with the same configuration you can use `start_server / stop_server` methods.

    before(:all) do
      configuration = {} # Your configuration hash
      @config = NginxTestHelper::Config.new("example_config_id", configuration)
      start_server(@config)
    end

    after(:all) do
      stop_server(@config)
    end

### delete_config_and_log_files

You can use this method to delete the files created by configuration.
One usecase is call it after the test, if it has passed, like:

	RSpec.configure do |config|
	  config.after(:each) do
	    NginxTestHelper::Config.delete_config_and_log_files(config_id) if has_passed?
	  end
	end

## Environment variables

Some default values can be overwriten by environment variables.
Check the list bellow:

1. NGINX_EXEC - set which nginx executable to be used on tests, default: '/usr/local/nginx/sbin/nginx'
2. NGINX_HOST - set the host returned by `nginx_host` method, default: '127.0.0.1'
3. NGINX_PORT - set the port returned by `nginx_port` method, default: 9990
4. NGINX_WORKERS - set the number of workers returned by `nginx_workers` method, default: 1
5. NGINX_TESTS_TMP_DIR - set the dir where temporary files, logs and configuration files, will be stored, default: '/tmp/nginx_tests'

## Easter eggs

### configuration_template

You can set a key named `configuration_template` on your configuration with a template different from the one on `template_configuration` method to be used when writing configuration file.

### disable_start_stop_server

You can set a key named `disable_start_stop_server` on your configuration with `true` value to avoid the start and stop server steps. This can be useful when debugging how a test is failing.

### write_directive

You can use the method `write_directive` on your configuration template to be easier to deal with null values.

    write_directive("directive_name", value)

    with value = nil results in
    #directive_name "";

    with value != nil, 10 as example, results in
    directive_name "10";

There is a third optional parameter which is used as comment to directive.

    write_directive("directive_name", 10, "directive comment")

    #directive comment
    directive_name "10";

## Matchers

There are two available mathers.

### be_in_the_interval

To check if the value is in a range, `>= min` and `<= max`

    10.5.should be_in_the_interval(10.3, 10.6) # true
    10.5.should be_in_the_interval(10.6, 10.8) # false

### match_the_pattern

To check if the value match the given pattern

   "foo".should match_the_pattern(/O/i) # true
   "foo".should match_the_pattern(/A/i) # false

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
