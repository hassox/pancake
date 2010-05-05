require 'rubygems'
require 'hashie'
require 'extlib/class'
require 'extlib/boolean'
require 'extlib/module'
require 'extlib/nil'
require 'extlib/numeric'
require 'extlib/object'
require 'extlib/symbol'
require 'extlib/blank'
require "extlib/dictionary"
require 'extlib/logger'
require 'extlib/mash'
require 'extlib/hash'
require 'usher'
require 'usher/interface/rack'
require 'tilt'

module Pancake
  autoload    :Logger,          "pancake/logger"
  autoload    :Constants,       "pancake/constants"
  autoload    :Console,         "pancake/console"
  autoload    :Paths,           "pancake/paths"
  autoload    :Configuration,   "pancake/configuration"
  autoload    :BootLoaderMixin, "pancake/bootloaders"
  autoload    :MimeTypes,       "pancake/mime_types"
  autoload    :Middleware,      "pancake/middleware"
  autoload    :Router,          "pancake/router"
  autoload    :Errors,          "pancake/errors"
  autoload    :Stack,           "pancake/stack/stack"

  module Stacks
    autoload :Short,      "pancake/stacks/short"
  end

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
  end
end

require 'pancake/core_ext/class'
require 'pancake/core_ext/object'
require 'pancake/core_ext/symbol'
require 'pancake/master'
