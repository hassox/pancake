module Pancake
  class Configuration
    
    class Base      
      # Set a default on the the configuartion
      class << self
        def default(meth, *args, &block)
          value, description = args
          value = block if block
          defaults[meth][:value]       = value
          defaults[meth][:description] = description || ""
        end
      
        def defaults
          @defaults ||= Hash.new{|h,k| h[k] = {:value => nil, :description => ""}}
          @defaults
        end
        
        def description_for(field)
          defaults[field][:description]
        end
      end
      
      def singleton_class
        class << self; self; end
      end
      
      def defaults
        self.class.defaults
      end
      
      def description_for(field)
        self.class.description_for(field)
      end
      
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
              set_actual_value(name, defaults[name][:value])
            end
          else
            set_actual_value(name, nil)
          end            
        end
      end
      
      def set_actual_value(name, val)
        singleton_class.class_eval <<-RUBY
          def #{name}=(val)
            values[#{name.inspect}] = val
          end
          
          def #{name}
            values[#{name.inspect}]
          end
        RUBY
        values[name] = val
      end
      
    end # Base
    
    class << self
      
      # Make a new configuration class
      def make(&block)
        Class.new(Pancake::Configuration::Base, &block)
      end
      
    end # self
    
  end # Configuration
end # Pancake