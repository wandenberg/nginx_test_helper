module NginxTestHelper
  module EnvMethods
    module ClassMethods
      def nginx_address
        "http://#{nginx_host}:#{nginx_port}"
      end

      def nginx_executable
        ENV['NGINX_EXEC'].nil? ? "/usr/local/nginx/sbin/nginx" : ENV['NGINX_EXEC']
      end

      def nginx_host
        ENV['NGINX_HOST'].nil? ? "127.0.0.1" : ENV['NGINX_HOST']
      end

      def nginx_port
        ENV['NGINX_PORT'].nil? ? "9990" : ENV['NGINX_PORT']
      end

      def nginx_workers
        ENV['NGINX_WORKERS'].nil? ? "1" : ENV['NGINX_WORKERS']
      end

      def nginx_tests_tmp_dir
        ENV['NGINX_TESTS_TMP_DIR'].nil? ? "/tmp/nginx_tests" : ENV['NGINX_TESTS_TMP_DIR']
      end

      def nginx_tests_cores_dir
        File.join(nginx_tests_tmp_dir, "cores")
      end

      def nginx_tests_core_dir(current_test)
        File.join(nginx_tests_cores_dir, current_test)
      end

      def nginx_event_type
        (RUBY_PLATFORM =~ /darwin/) ? 'kqueue' : 'epoll'
      end
    end

    include ClassMethods

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
