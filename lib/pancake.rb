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

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'pancake/paths'
require 'pancake/hooks/on_inherit'
require 'pancake/hooks/inheritable_inner_classes'
require 'pancake/core_ext/class'
require 'pancake/core_ext/object'
require 'pancake/core_ext/symbol'
require 'pancake/configuration'
require 'pancake/bootloaders'
require 'pancake/middleware'
require 'pancake/router'
require 'pancake/master'
require 'pancake/stack/stack'
require 'pancake/stack/configuration'
require 'pancake/stack/router'
require 'pancake/stack/bootloader'
require 'pancake/stack/app'

module Pancake
  autoload :Controller, "pancake/more/controller"
  
  module Stacks
    autoload :Short,    "pancake/stacks/short"
  end
end