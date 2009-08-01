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
require "extlib/dictionary"

%w(
  paths
  hooks/on_inherit
  hooks/inheritable_inner_classes
  core_ext/class
  core_ext/object
  core_ext/symbol
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
  more/controller
).each do |file|
  path = File.join(File.dirname(__FILE__), "pancake")
  require File.join(path, file)
end