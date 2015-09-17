require 'rake/testtask'
require 'rdoc/task'

task default: %w[test rdoc]

Rake::TestTask.new do |t|
  t.libs << "tests"
  t.test_files = FileList['tests/test*.rb']
  t.verbose = true
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/*.rb")
  #rdoc.options << "-C1"
end
