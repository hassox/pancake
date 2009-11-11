# Enter any global configuration for the stack in this file.

class <%= stack_name.camel_case %>
  # include middleware for the development stack
  # Labels can be set in the config/environments/<env>.rb file to limit
  # middleware loading.
  # stack(:middleware_name, :labels => [:development, :production]).use(MiddlewareClass)

  class self::Configuration
    # Add defaults to your stack configuration.
    # This is scoped to this stack, and is inhertied into child stacks
    #
    # Fixed value defaults:
    #   default :var_name, :value, "A description of the variable"
    #
    # Lazy Defaults:
    #   default :var_name, lambda{ configuration_method }, "Some Description"

    # Declare methods on your configuraiton
    # def configuration_method; #stuff; end
  end
end

