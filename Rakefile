require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

RuboCop::RakeTask.new

desc 'Run default tasks'
task default: :test
task default: :rubocop
