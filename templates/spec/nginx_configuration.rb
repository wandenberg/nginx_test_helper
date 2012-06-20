require 'nginx_test_helper'
module NginxConfiguration
  def self.default_configuration
    {
      :disable_start_stop_server => false,
      :master_process => 'off',
      :daemon => 'off',

      :unknown_value => nil,

      :return_code => 202
    }
  end


  def self.template_configuration
  %(
pid               <%= pid_file %>;
error_log         <%= error_log %> debug;

worker_processes  <%= nginx_workers %>;

events {
  worker_connections  1024;
  use                 <%= (RUBY_PLATFORM =~ /darwin/) ? 'kqueue' : 'epoll' %>;
}

http {
  access_log      <%= access_log %>;

  client_body_temp_path <%= client_body_temp %>;

  server {
    listen        <%= nginx_port %>;
    server_name   <%= nginx_host %>;

    location / {
      <%= write_directive("unknown_directive", unknown_value) %>
      <%= write_directive("return", return_code, "return_code") %>
    }
  }
}
  )
  end
end
