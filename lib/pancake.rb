require 'rubygems'
require 'rack/router'
require 'extlib/class'
require 'extlib/boolean'
require 'extlib/module'
require 'extlib/nil'
require 'extlib/numeric'
require 'extlib/object'
require 'extlib/symbol'
require 'extlib/blank'

%w(
  hooks/on_inherit
  hooks/inheritable_inner_classes
  core_ext/object
  configuration
  bootloaders
  middleware
  router
  master
  stack/stack
  stack/configuration
  stack/app
  stack/router
  stack/bootloader
).each do |file|
  path = File.join(File.dirname(__FILE__), "pancake")
  require File.join(path, file)
end