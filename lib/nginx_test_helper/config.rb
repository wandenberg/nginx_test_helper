require "nginx_test_helper/env_methods"
require "erb"

module NginxTestHelper
  class Config

    include NginxTestHelper::EnvMethods

    attr_reader :config_id, :configuration

    def initialize(config_id, configuration)
      @config_id = config_id
      @configuration = NginxConfiguration.default_configuration.merge(configuration).merge(Config.files_and_dirs(config_id))

      Config.create_dirs
      create_configuration_file
    end

    def create_configuration_file
      configuration_template = configuration.delete(:configuration_template)
      template = ERB.new configuration_template || NginxConfiguration.template_configuration
      File.open(configuration[:configuration_filename], 'w') {|f| f.write(template.result(get_binding)) }
    end

    def respond_to?(m)
      super(m) || configuration.has_key?(m.to_sym)
    end

    def method_missing(m, *args, &block)
      raise NameError, "undefined local variable, method or configuration '#{m}'" unless configuration.has_key?(m.to_sym)
      configuration[m.to_sym]
    end

    def write_directive(name, value, comment=nil)
      directive = []
      directive << %(##{comment}) unless comment.nil?
      if (value.is_a?(Array))
        directive << %(#{"#" if value.empty?}#{name} #{value.join(" ")};)
      else
        directive << %(#{"#" if value.nil?}#{name} "#{value}";)
      end
      directive.join("\n")
    end

    def get_binding
      binding
    end

    class << self
      def create_dirs
        FileUtils.mkdir_p("#{nginx_tests_tmp_dir}/logs") unless File.directory?("#{nginx_tests_tmp_dir}/logs")
        FileUtils.mkdir_p("#{nginx_tests_tmp_dir}/client_body_temp") unless File.directory?("#{nginx_tests_tmp_dir}/client_body_temp")
      end

      def files_and_dirs(config_id)
        {
          :configuration_filename => File.expand_path("#{nginx_tests_tmp_dir}/#{config_id}.conf"),
          :pid_file => File.expand_path("#{nginx_tests_tmp_dir}/nginx.pid"),
          :access_log => File.expand_path("#{nginx_tests_tmp_dir}/logs/access-#{config_id}.log"),
          :error_log => File.expand_path("#{nginx_tests_tmp_dir}/logs/error-#{config_id}.log"),
          :client_body_temp => File.expand_path("#{nginx_tests_tmp_dir}/client_body_temp")
        }
      end

      def delete_config_and_log_files(config_id)
        items = files_and_dirs(config_id)

        File.delete(items[:configuration_filename]) if File.exist?(items[:configuration_filename])
        File.delete(items[:access_log]) if File.exist?(items[:access_log])
        File.delete(items[:error_log]) if File.exist?(items[:error_log])
        FileUtils.rm_rf(items[:client_body_temp]) if File.exist?(items[:client_body_temp])
      end
    end
  end
end
