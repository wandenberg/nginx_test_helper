#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color --format documentation]
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => [:spec]
