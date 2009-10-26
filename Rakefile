require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pancake"
    gem.summary = %Q{Eat Pancake Stacks for Breakfast}
    gem.description = %Q{Eat Pancake Stacks for Breakfast}
    gem.email = "has.sox@gmail.com"
    gem.homepage = "http://github.com/hassox/pancake"
    gem.authors = ["Daniel Neighman"]
    gem.add_development_dependency "rspec"
    gem.add_dependency "usher", ">=0.5.9"
    gem.add_dependency "mynyml-rack-accept-media-types"
    gem.require_path = 'lib'
    gem.autorequire = 'pancake'
    gem.bindir = "bin"
    gem.executables = %w( pancake-gen )
    gem.files = %w(LICENSE README.textile Rakefile TODO) + Dir.glob("{lib,spec,bin}/**/{*,.[a-z]*}")
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = %w(--format progress --color)
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "pancake #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
