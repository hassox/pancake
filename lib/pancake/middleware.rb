module Pancake
  # Provides a mixin to use on any class to give it middleware management capabilities.
  # This module provides a rich featureset for defining a middleware stack.
  #
  # Middlware can be set before, or after other middleware, can be tagged / named,
  # and can be declared to only be active in certain types of stacks.
  module Middleware

    # When extending a base class with the Pancake::Middleware,
    # an inner class StackMiddleware is setup on the base class.
    # This inner class is where all the inforamation is stored on the stack to be defined
    # The inner StackMiddleware class is also set to be inherited
    # with the base class (and all children classes)
    # So that each class gets its own copy and may maintain the base
    # stack from the parent, but edit it in the child.
    def self.extended(base)
      base.class_eval <<-RUBY
        class StackMiddleware < Pancake::Middleware::StackMiddleware; end
      RUBY
      if base.is_a?(Class)
        base.inheritable_inner_classes :StackMiddleware
      end
      super
    end # self.extended

    # Build a middleware stack given an application and some middleware classes
    #
    # @param [Object] app a rack application to wrap in the middlware list
    # @param [Array<StackMiddleware>] mwares an array of
    # StackMiddleware instances where each instance
    #   defines a middleware to use in constructing the stack
    #
    # @example
    #   Pancake::Middleware.build(@app, [MWare_1, MWare_2])
    # @return [Object]
    #   An application instance of the first middleware defined in the array
    #   The application should be an instance that conforms to Rack specifications
    #
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def self.build(app, mwares)
      mwares.reverse.inject(app) do |a, m|
        m.middleware.new(a, *m.args, &m.block)
      end
    end

    # @param [Array<Symbol>] labels An array of labels specifying the stack labels to use to build the middlware list
    #
    # @example
    #   MyApp.middlewares(:production) # provides all middlewares matching the :production label, or the implicit :any label
    #   MyApp.middlewares(:development, :demo) # provides all middlewares matching the :development or :demo or implicit :any label
    #
    # @return [Array<StackMiddleware>]
    #   An array of middleware specifications in the order they should be used to wrap the application
    #
    # @see Pancake::Middleware::StackMiddleware
    # @see Pancake.stack_labels for a decription of stack_labels
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def middlewares(*labels)
      labels = labels.flatten
      self::StackMiddleware.middlewares(*labels)
    end

    # Useful for adding additional information into your middleware stack  definition
    #
    # @param [Object] name
    #   The name of a given middleware.  Each piece of middleware has a name in the stack.
    #   By naming middleware we can refer to it later, swap it out for a different class or even just remove it from the stack.
    # @param        [Hash] opts An options hash
    # @option opts  [Array<Symbol>] :labels ([:any])
    #   An array of symbols, or a straight symbol that defines what stacks this middleware sould be active in
    # @option opts [Object] :before
    #   Sets this middlware to be run after the middleware named.  Name is either the name given to the
    #   middleware stack, or the Middleware class itself.
    # @option opts [Object] :after
    #   Sets this middleware to be run after the middleware name.  Name is either the name given to the
    #   middleware stack or the Middleware class itself.
    #
    # @example Declaring un-named middleware via the stack
    #   MyClass.stack.use(MyMiddleware)
    #
    # This middleware will be named MyMiddleware, and can be specified with (:before | :after) => MyMiddleware
    #
    # @example Declaring a named middleware via the stack
    #   MyClass.stack(:foo).use(MyMiddleware)
    #
    # This middleware will be named :foo and can be specified with (:before | :after) => :foo
    #
    # @example Declaring a named middleware with a :before key
    #   MyClass.stack(:foo, :before => :bar).use(MyMiddleware)
    #
    # This middleware will be named :foo and will be run before the middleware named :bar
    # If :bar is not run, :foo will not be run either
    #
    # @example Declaring a named middlware with an :after key
    #   MyClass.stack(:foo, :after => :bar).use(MyMiddleware)
    #
    # This middleware will be named :foo and will be run after the middleware named :bar
    # If :bar is not run, :foo will not be run either
    #
    # @example Declaring a named middleware with some labels
    #   MyClass.stack(:foo, :lables => [:demo, :production, :staging]).use(MyMiddleware)
    #
    # This middleware will only be run when pancake is set with the :demo, :production or :staging labels
    #
    # @example A full example
    #   MyClass.stack(:foo, :labels => [:staging, :development], :after => :session).use(MyMiddleware)
    #
    #
    # @see Pancake::Middleware#use
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def stack(name = nil, opts = {})
      if self::StackMiddleware._mwares[name] && mw = self::StackMiddleware._mwares[name]
        unless mw.stack == self
          mw = self::StackMiddleware._mwares[name] = self::StackMiddleware._mwares[name].dup
        end
        mw
      else
        self::StackMiddleware.new(name, self, opts)
      end
    end

    # Adds middleware to the current stack definition
    #
    # @param [Class] middleware  The middleware class to use in the stack
    # @param [Hash]  opts        An options hash that is passed through to the middleware when it is instantiated
    #
    # @yield The block is provided to the middlewares #new method when it is initialized
    #
    # @example Bare use call
    #   MyApp.use(MyMiddleware, :some => :option){ # middleware initialization block here }
    #
    # @example Use call after a stack call
    #   MyApp.stack(:foo).use(MyMiddleware, :some => :option){ # middleware initialization block here }
    #
    # @see Pancake::Middleware#stack
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def use(middleware, *_args, &block)
      stack(middleware).use(middleware, *_args, &block)
    end # use

    # StackMiddleware manages the definition of the middleware stack for a given class.
    # It's instances are responsible for the definition of a single piece of middleware, and the class
    # is responsible for specifying the full stack for a given class.
    #
    # When Pancake::Middleware extends a class, an inner class is created in that class called StackMiddleware.
    # That StackMiddleware class inherits from Pancake::Middleware::StackMiddleware.
    #
    # @example The setup when Pancake::Middleware is extended
    #   MyClass.extend Pancake::Middleware
    #   # sets up
    #
    #   class MyClass
    #     class StackMiddleware < Pancake::Middleware::StackMiddleware; end
    #   end
    #
    # This is then set is an inheritable inner class on the extended class, such that when it is inherited,
    # the StackMiddleware class is inherited to an inner class of the same name on the child.
    class StackMiddleware
      # @api private
      class_inheritable_reader :_central_mwares, :_mwares, :_before, :_after
      @_central_mwares, @_before, @_after, @_mwares = [], {}, {}, {}

      # @api private
      attr_reader :middleware, :name
      # @api private
      attr_accessor :args, :block, :stack, :options

      class << self
        def use(mware, *_args, &block)
          new(mware).use(mware, *_args, &block)
        end

        # Resets this stack middlware.  Useful for specs
        def reset!
          _central_mwares.clear
          _mwares.clear
          _before.clear
          _after.clear
        end

        # Get the middleware list for this StackMiddleware for the given labels
        #
        # @param [Symbol] labels The label or list of labels to construct a stack from.
        #
        # @example Specified labels
        #   MyClass::StackMiddleware.middlewares(:production, :demo)
        #
        # @example No Labels Specified
        #   MyClass::StackMiddleware.middlewares
        #
        # This will include all defined middlewares in the given stack
        #
        # @return [Array<StackMiddleware>]
        #   An array of the middleware definitions to use in the order that they should be applied
        #   Takes into account all :before, :after settings and only constructs the stack where
        #   the labels are applied
        #
        # @see Pancake.stack_labels for a description on stack labels
        # @api public
        # @since 0.1.0
        # @author Daniel Neighman
        def middlewares(*labels)
          _central_mwares.map do |name|
            map_middleware(name, *labels)
          end.flatten
        end

        # Map the middleware for a given <name>ed middleware.  Applies the before and after groups of middlewares
        #
        # @param [Object] name    The name of the middleware to map the before and after groups to
        # @param [Symbol] labels  A label or list of labels to use to construct the middleware stack
        #
        # @example
        #   MyClass::StackMiddleware.map_middleware(:foo, :production, :demo)
        #
        # Constructs the middleware list based on the middleware named :foo, including all :before, and :after groups
        #
        # @return [Array<StackMiddleware>]
        #   Provides an array of StackMiddleware instances in the array [<before :foo>, <:foo>, <after :foo>]
        #
        # @api private
        # @since 0.1.0
        # @author Daniel Neighman
        def map_middleware(name, *labels)
          result = []
          _before[name] ||= []
          _after[name]  ||= []
          if _mwares[name] && _mwares[name].use_for_labels?(*labels)
            result << _before[name].map{|n| map_middleware(n)}
            result << _mwares[name]
            result << _after[name].map{|n| map_middleware(n)}
            result.flatten
          end
          result
        end

        # Provides access to a named middleware
        #
        # @param [Object] name The name of the defined middleware
        #
        # @return [StackMiddleware] The middleware definition associated with <name>
        #
        # @api public
        # @since 0.1.0
        # @author Daniel Neighman
        def [](name)
          _mwares[name]
        end
      end

      # Provides access to a named middleware
      #
      # @see Pancake::Middleware::StackMiddleware.[] for an explaination
      # @since 0.1.0
      # @author Daniel Neighman
      def [](name)
        self.class._mwares[name]
      end

      # @param          [Object]  name a name for this middleware definition.  Usually a symbol, but could be the class.
      # @param          [Object]  stack the stack owner of this middleware.
      # @param          [Hash]    options an options hash.  Provide labels for this middleware.
      # @option options [Array]   :labels ([:any])
      #   The labels that are associated with this middleware
      # @option options [Object]  :before A middleware name to add this middleware before
      # @option options [Object]  :after A middleware name to add this middleware after
      #
      # @see Pancake::Middleware.stack_labels
      # @api private
      # @author Daniel Neighman
      def initialize(name, stack, options = {})
        @name, @stack, @options = name, stack, options
        @options[:labels] ||= [:any]
      end

      # Delete this middleware from the current stack
      #
      # @api public
      # @since 0.1.0
      # @author Daniel Neighman
      def delete!
        self.class._mwares.delete(name)
        self.class._before.delete(name)
        self.class._after.delete(name)
        self.class._central_mwares.delete(name)
        self
      end

      # Specify the actual middleware definition to use
      #
      # @param [Class] mware   A Middleware class to use.  This should be a class of Middleware which conforms to the Rack spec
      # @param [Hash]  config  A configuration hash to give to the middleware class on initialization
      # @yield The block is passed to the middleware on initialization
      #
      # @see Pancake::Middleware.use
      # @api public
      # @since 0.1.0
      # @author Daniel Neighman
      def use(mware, *_args, &block)
        @middleware, @args, @block = mware, _args, block
        @name = @middleware if name.nil?
        if options[:before]
          raise "#{options[:before].inspect} middleware is not defined for this stack" unless self.class._mwares.keys.include?(options[:before])
          self.class._before[options[:before]] ||= []
          self.class._before[options[:before]] << name
        elsif options[:after]
          raise "#{options[:after].inspect} middleware is not defined for this stack" unless self.class._mwares.keys.include?(options[:after])
          self.class._after[options[:after]] ||= []
          self.class._after[options[:after]] << name
        else
          self.class._central_mwares << name unless self.class._central_mwares.include?(name)
        end
        self.class._mwares[name] = self
        self
      end

      # Checks if this middleware definition should be included from the labels given
      # @param [Symbol] labels The label or list of labels to check if this middleware should be included
      #
      # @return [Boolean] true if this middlware should be included
      #
      # @api private
      # @since 0.1.0
      # @author Daniel Neighman
      def use_for_labels?(*labels)
        return true if labels.empty? || options[:labels].nil? || options[:labels].include?(:any)
        !(options[:labels] & labels).empty?
      end

      # @api private
      def dup
        result = super
        result.args = result.args.map{|element| element.dup}
        result.options = result.options.dup
        result
      end
    end
  end # Middleware
end # Pancake
