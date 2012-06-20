module NginxTestHelper
  class CommandLineTool
    def cwd
      File.expand_path(File.join(File.dirname(__FILE__), '../../'))
    end

    def expand(*paths)
      File.expand_path(File.join(*paths))
    end

    def template_path(filepath)
      expand(cwd, File.join("templates", filepath))
    end

    def dest_path(filepath)
      expand(Dir.pwd, filepath)
    end

    def copy_unless_exists(relative_path, dest_path = nil)
      unless File.exist?(dest_path(relative_path))
        FileUtils.copy(template_path(relative_path), dest_path(dest_path || relative_path))
      end
    end

    def process(argv)
      if argv[0] == 'init'
        require 'fileutils'

        FileUtils.makedirs(dest_path('spec'))

        copy_unless_exists('spec/nginx_configuration.rb')
        copy_unless_exists('spec/example_spec.rb')

        write_mode = 'w'
        if File.exist?(dest_path('spec/spec_helper.rb'))
          load dest_path('spec/spec_helper.rb')
          write_mode = 'a'
        end

        unless Object.const_defined?('NginxConfiguration') && write_mode == 'a'
          File.open(dest_path('spec/spec_helper.rb'), write_mode) do |f|
            f.write("\nrequire File.expand_path('nginx_configuration', File.dirname(__FILE__))")
          end
        end

        File.open(template_path('INSTALL'), 'r').each_line do |line|
          puts line
        end
      elsif argv[0] == "license"
        puts File.new(expand(cwd, "LICENSE")).read
      else
        puts "unknown command #{argv}"
        puts "Usage: nginx_test_helper init"
        puts "                         license"
      end
    end
  end
end
