require 'rubygems'
require 'extlib/class'
require 'extlib/boolean'
require 'extlib/module'
require 'extlib/nil'
require 'extlib/numeric'
require 'extlib/object'
require 'extlib/symbol'
require 'extlib/blank'
require "extlib/dictionary"
require 'usher'
require 'tilt'

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
require 'pancake/errors'
require 'pancake/stack/stack'
require 'pancake/stack/configuration'
require 'pancake/stack/router'
require 'pancake/stack/bootloader'
require 'pancake/stack/app'
require 'pancake/mixins/request_helper'

module Pancake

  module Stacks
    autoload :Short,    "pancake/stacks/short"
  end

  module Mixins
    autoload :Publish,  "pancake/mixins/publish"
    autoload :Render,   "pancake/mixins/render"
  end
end
