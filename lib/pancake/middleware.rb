module Pancake
  module Middleware
    
    def self.build(app, mwares)
      mwares.reverse.inject(app) do |a, m|
         m.middleware.new(a, m.options, &m.block)
      end
    end
    
    def self.extended(base)
      base.class_eval <<-RUBY
        class StackMiddleware < Pancake::Middleware::StackMiddleware; end
      RUBY
      if base.is_a?(Class)
        base.inheritable_inner_classes :StackMiddleware
      end
    end # self.extended
    
    def middlewares(*labels)
      self::StackMiddleware.middlewares(*labels)
    end
    
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
    
    # Use this to define middleware to include in the stackå
    # :api: public
    def use(middleware, opts = {}, &block)
      stack(middleware).use(middleware, opts, &block)
    end # use
    
    # use this to prepend middleware to the stack
    # :api: public
    # def prepend_use(middleware, opts = {}, &block)
    #   middlewares.unshift SomeMiddleware.new(middleware, opts, &block)
    # end
    
    class StackMiddleware
      # :api: private
      class_inheritable_reader :_central_mwares, :_mwares, :_before, :_after
      @_central_mwares, @_before, @_after, @_mwares = [], {}, {}, {}
      
      attr_reader :middleware, :name
      attr_accessor :config, :block, :stack, :options
      
      class << self
        def use(mware, opts, &block)
          new(mware).use(mware, opts, &block)
        end
        
        def reset!
          _central_mwares.clear
          _mwares.clear
          _before.clear
          _after.clear
        end
        
        def middlewares(*labels)
          _central_mwares.map do |name|
            map_middleware(name, *labels)
          end.flatten
        end
        
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
        
        def [](name)
          _mwares[name]
        end
      end
      
      def [](name)
        self.class._mwares[name]
      end
      
      def initialize(name, stack, options = {})
        @name, @stack, @options = name, stack, options
        @options[:labels] ||= [:any]
      end
      
      # delete this middleware from the stack
      # :api: public
      def delete!
        self.class._mwares.delete(name)
        self.class._before.delete(name)
        self.class._after.delete(name)
        self.class._central_mwares.delete(name)
        self
      end
      
      def use(mware, config = {}, &block)
        @middleware, @config, @block = mware, config, block
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
      
      def use_for_labels?(*labels)
        return true if labels.empty? || options[:labels].nil? || options[:labels].include?(:any)
        !(options[:labels] & labels).empty?
      end
      
      def dup
        result = super
        result.config = result.config.dup
        result.options = result.options.dup
        result
      end
    end
  end # Middleware
end # Pancake