module Pancake
  class Configuration
    
    class Base     
      class_inheritable_reader :defaults 
      @defaults = Hash.new{|h,k| h[k] = {:value => nil, :description => ""}}
      
      # Set a default on the the configuartion
      class << self

        # Set a default for this configuration class
        # Provide a field/method name and a value to set this to.  
        # If you don't provide a value, and instead provide a block, then 
        # a proc will be called lazily when requested.
        # 
        # Example
        #   config_klass = Pancake::Configuration.make
        #   config_class.default :foo, :bar, "This foo is a bar"
        #   config = config_class.new
        #
        # :api: public 
        def default(meth, *args, &block)
          value, description = args
          if block
            description = value
            value = block
          end
          defaults[meth][:value]       = value
          defaults[meth][:description] = description || ""
        end
        
        # Provides aaccess to the description for a default setting
        # 
        # :api: public
        def description_for(field)
          defaults.keys.include?(field) ? defaults[field][:description] : ""
        end
      end
      
      # access to the singleton class
      # :api: private
      def singleton_class # :nodoc:
        class << self; self; end
      end
      
      # Access to the configuration defaults via the instance.  Defers to the 
      # clas smethod for defaults
      # :api: public
      def defaults
        self.class.defaults
      end
      
      # Access to the class descritpion for defaults
      # :api: public
      def description_for(field)
        self.class.description_for(field)
      end
      
      # Access to the currently set values for this configuration object
      # :api: public
      def values
        @values ||= {}
      end
          
      private
      def method_missing(name, *args)
        if name.to_s =~ /(.*?)=$/
          set_actual_value($1.to_sym, args.first)
        else
          if defaults.keys.include?(name) # We don't want to trigger a default value if we're blindly setting it
            # If the default is a proc, do not cache it
            case defaults[name][:value]
            when Proc
              instance_eval(&defaults[name][:value])
            else
              val = defaults[name][:value]
              val = val.dup rescue val
              set_actual_value(name, val)
            end
          else
            nil
          end            
        end
      end
      
      # Caches the values via a method rather than going through method_missing
      # :api: private
      def set_actual_value(name, val) # :nodoc:
        singleton_class.class_eval <<-RUBY
          def #{name}=(val)                               # def foo=(val)
            values[#{name.inspect}] = val                 #   values[:foo] = val
          end                                             # end
          
          def #{name}                                     # def foo
            values[#{name.inspect}]                       #   values[:foo]   
          end                                             # end
        RUBY
        values[name] = val
      end
      
    end # Base
    
    class << self
      
      # Make a new configuration class
      # :api: public
      def make(&block)
        Class.new(Pancake::Configuration::Base, &block)
      end
      
    end # self
  end # Configuration
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
end # Pancake