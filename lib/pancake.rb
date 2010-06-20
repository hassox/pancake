require 'rubygems'
#require 'hashie'
$:.unshift File.join(File.dirname(__FILE__), "pancake", "vendor", "hashie", "lib")
require 'hashie'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/core_ext/string/inflections'
require 'active_support/ordered_hash'
require 'http_router'
require 'tilt'

module Pancake
  autoload    :Logger,          "pancake/logger"
  autoload    :Constants,       "pancake/constants"
  autoload    :Console,         "pancake/console"
  autoload    :Paths,           "pancake/paths"
  autoload    :Configuration,   "pancake/configuration"
  autoload    :MimeTypes,       "pancake/mime_types"
  autoload    :Middleware,      "pancake/middleware"
  autoload    :Router,          "pancake/router"
  autoload    :Errors,          "pancake/errors"
  autoload    :Stack,           "pancake/stack/stack"
  autoload    :PancakeConfig,   "pancake/defaults/configuration"

  module Hooks
    autoload :OnInherit,                'pancake/hooks/on_inherit'
    autoload :InheritableInnerClasses,  'pancake/hooks/inheritable_inner_classes'
  end

  module Mixins
    autoload :RequestHelper,  "pancake/mixins/request_helper"
    autoload :Publish,        "pancake/mixins/publish"
    autoload :Render,         "pancake/mixins/render"
    autoload :StackHelper,    "pancake/mixins/stack_helper"
    autoload :ResponseHelper, "pancake/mixins/response_helper"
  end

  module Middlewares
    autoload :Static,       "pancake/middlewares/static"
    autoload :Logger,       "pancake/middlewares/logger"
  end

  module Test
    autoload :Matchers,    "pancake/test/matchers"
    autoload :Helpers,     "pancake/test/helpers"
  end
end

require 'pancake/core_ext/class'
require 'pancake/core_ext/object'
require 'pancake/core_ext/symbol'
require 'pancake/master'
