require File.join(File.dirname(__FILE__), "publish", "action_options")
module Pancake
  module Mixins
    module Publish
      
      def self.extended(base)
        base.class_eval do
          class_inheritable_accessor :actions, :formats
          self.actions = {}
          self.formats = [:html]
        end
      end
    
      # Accepts a list of symbols representing the formats each action in the
      # controller will return. By default the list consists only of :html 
      #
      #   provides :html, :xml
      #
      # :api public
      def provides(*args)
        self.formats = args
      end
    
      private
    
      # Causes the next method added immediately after it’s call to be defined 
      # as an action. It also generates an instance of ActionOptions, which 
      # encapsulates all the parameters the action accepts/expects and also
      # the formats that it can potentially return.
      #
      #   publish :id => as_integer(:req)
      #   def show
      #     ...
      #   end
      #
      # The example above publishes the action "show" and configures the 
      # following options for it:
      #
      # - The parameter 'id' will be coerced into an Integer
      # - It also must not be blank, it is required.
      #
      # The publish declaration can also create much more sophisticated 
      # constraints. You can declare a parameter as optional, give it a default
      # value if it is missing.
      #
      # Here, 'start' and 'end' are required — the default — and are coerced into
      # date values. The 'page' parameter is optional, with the default being 1.
      #
      #   publish :start => as_date, :end => as_date :page => as_integer(1)
      #
      # For a list of the built in coercions look in the API for methods prefixed
      # with 'as_'. These are intended to be used in your publish declarations.
      #
      # #publish can also handle the specification of formats for an action. It
      # accepts an additional two options, :provides and :only_provides.
      #
      # To the list of globally declared formats, :provides adds additional 
      # formats to an action.
      # 
      #   publish :provides => :xml
      #
      # The :only_provides option overrides any globally declared formats for an
      # action.
      #
      #   publish :only_provides => [:json, :xml]
      #
      # :api: public
      def publish(opts = {})
        @pending_publication_opts = opts
      end
    
      # Used when declaring configuration for parameters in the publish
      # declaration. It returns an array of the type, default value an 
      # additional options.
      #
      # @param type [Object] The
      #
      # The current supported types are
      # - :integer
      # - :date
      # - :string
      #
      # For details on the options supported by each type, please see the 
      # corresponding methods declared in the ActionOptions class. These methods
      # are named as the type, prefixed with 'validate_and_coerce_'
      #
      #
      # @example
      #   Here is an example where we declare an integer and that it is required
      #
      #     as(:integer, :req)
      #
      #   Or that it is optional, but has a default value if it is missing.
      #
      #     as(:integer, 21)
      #
      # @api public
      def as(type, default = :req, opts = {})
        [type, default, opts]
      end
    
      # Takes a parameters hash, and validates each entry against the options
      # defined for this action. It will flag required params when missing, 
      # insert defaults or coerce values into the desired type. It mutates
      # the params hash itself.
      #
      # :api: private
      def validate_and_coerce_params(action, params)
        actions[action].validate_and_coerce(params)
      end
    
    
      # This hook is used in conjunction with the #publish method to expose 
      # instance methods as actions. Obviously, it should never be called 
      # directly :)
      #
      # :api: private
      def method_added(name)
        super
        if @pending_publication_opts
          self.actions[name.to_s] = ActionOptions.new(formats, @pending_publication_opts)
          @pending_publication_opts = nil
        end
      end
    end # Publish
  end # Mixins
end # Pancake
