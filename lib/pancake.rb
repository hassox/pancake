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
  autoload    :Logger,    "pancake/logger"
  autoload    :Constants, "pancake/constants"
  autoload    :Console,   "pancake/console"

  module Stacks
    autoload :Short,      "pancake/stacks/short"
  end

  module Mixins
    autoload :RequestHelper,"pancake/mixins/request_helper"
    autoload :Publish,      "pancake/mixins/publish"
    autoload :Render,       "pancake/mixins/render"
    autoload :StackHelper, "pancake/mixins/stack_helper"
    autoload :ResponseHelper,  "pancake/mixins/response_helper"
  end

  module Middlewares
    autoload :Static,       "pancake/middlewares/static"
    autoload :Logger,     "pancake/middlewares/logger"
  end

  module Test
    autoload :Matchers,    "pancake/test/matchers"
  end

end

require 'pancake/paths'
require 'pancake/hooks/on_inherit'
require 'pancake/hooks/inheritable_inner_classes'
require 'pancake/core_ext/class'
require 'pancake/core_ext/object'
require 'pancake/core_ext/symbol'
require 'pancake/configuration'
require 'pancake/bootloaders'
require 'pancake/mime_types'
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
require 'pancake/defaults/middlewares'
require 'pancake/defaults/configuration'
