module Pancake
  class Stack
    
    module BootLoaderMixin
      class Base
        # :api: :public
        attr_accessor :stack, :config
        
        def initialize(stack, config)
          @stack, @config = stack, config
        end
        
        # Creates a new instance and runs it
        # :api: private
        def self.call(stack, config)
          new(stack, config).run!
        end        
      end
      
      # Provides access to an individual bootloader
      # :api: public
      def [](name)
        _bootloaders[name]
      end
      
      # Add a bootloader.  Inside the block we're inside a class definition.  
      # Requirements: define a +run!+ method
      #
      # Example
      #   FooStack::BootLoader.add(:foo) do
      #     def run!
      #       # stuff
      #     end
      #   end
      # 
      # :api: public
      def add(name, opts = {}, &block)
        _bootloaders[name] = Class.new(Pancake::Stack::BootLoaderMixin::Base, &block)
        
        # If there are no before or after keys, add it to the central bootloaders
        if opts[:before]
          _bootloader_map[opts[:before]][:before] << name
        elsif opts[:after]
          _bootloader_map[opts[:after]][:after] << name
        else
          _central_bootloaders << name
        end         
        
        _bootloaders[name]
      end      
      
      # Runs the bootloaders in order
      # :api: private 
      def run! # :nodoc: 
        each do |name, bl|
          bl.call(stack, :foo)
        end
      end
      
      # Set the stack that this bootloader is responsible for.
      # :api: private
      def stack=(stack) # :nodoc:
        @stack = stack
      end
      
      # Access to the stack that this bootloader is responsible for
      # :api: public
      def stack
        @stack
      end
      
      # Resets the bootloaders on the stack
      # :api: public
      def reset!
        _central_bootloaders.clear
        _bootloaders.clear
        _bootloader_map.clear
      end
      
      # Yields each bootloader in order along with it's name
      # 
      # Example
      #   FooStack::BootLoader.each do |name, bootloader|
      #     # do stuff
      #   end
      # 
      # :api: public
      def each
        _map_bootloaders(_central_bootloaders).each do |n|
          yield n, _bootloaders[n]
        end
      end
      
      private
      # Tracks the central bootloaders.  The central bootloaders are like the spine of the bootloader system
      # All other bootloaders hang off either before or after the central bootloaders
      # :api: private
      def _central_bootloaders # :nodoc:
        @_central_bootloaders ||= []
      end
      
      # Keeps track of bootloaders to run before or after other bootloaders
      # :api: private
      def _bootloader_map # :nodoc:
        @_bootloader_map ||= Hash.new{|h,k| h[k] = {:before => [], :after => []}}
      end
      
      # Provide access to the raw bootloader classes
      # :api: private
      def _bootloaders # :nodoc:
        @_bootloaders ||= {}
      end
      
      # Map out the bootloaders by name to run.
      # :api: private
      def _map_bootloaders(names)
        names.map do |name|
          r = []
          r << _map_bootloaders(_bootloader_map[name][:before])
          r << name
          r << _map_bootloaders(_bootloader_map[name][:after])
        end.flatten
      end

    end # BootLoaders
    
    ## Add the bootloaders to the new application stack
    Pancake::Stack.on_inherit do |base|
      base.class_eval do
        class BootLoader
          extend BootLoaderMixin
          extend Enumerable
        end
        BootLoader.stack = base
        BootLoader.reset!
      end
    end # Pancake::Stack.on_inherit
    
  end # Stack
end # Pancake