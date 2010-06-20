# -*- encoding: utf-8 -*-
require 'bundler'

Gem::Specification.new do |s|
  s.name = 'pancake'
  s.version = File.read('VERSION')
  s.homepage = %q{http://github.com/hassox/pancake}
  s.authors = ["Daniel Neighman"]
  s.autorequire = %q{pancake}
  s.date = Date.today
  s.default_executable = %q{pancake}
  s.description = %q{Eat Pancake Stacks for Breakfast}
  s.email = %q{has.sox@gmail.com}

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.executables = ["pancake"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Eat Pancake Stacks for Breakfast}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile",
     "TODO.textile"
  ]
  s.files = %w(LICENSE README.textile Rakefile TODO.textile) + Dir.glob("{lib,spec,bin}/**/{*,.[a-z]*}")

  s.add_bundler_dependencies
end

