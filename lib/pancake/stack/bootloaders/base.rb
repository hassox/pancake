module Pancake
  class Stack
    
    module BootLoaderMixin
      class Base
        attr_accessor :stack, :config
        
        def initialize(stack, config)
          @stack, @config = stack, config
        end
        
        def self.call(stack, config)
          new(stack, config).run!
        end        
      end
      
      def [](name)
        _bootloaders[name]
      end
      
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
      
      # Runs the bootloaders
      # :api: private 
      def run!
        each do |name, bl|
          bl.call(stack, :foo)
        end
      end
      
      def stack=(stack)
        @stack = stack
      end
      
      def stack
        @stack
      end
      
      def reset!
        _central_bootloaders.clear
        _bootloaders.clear
        _bootloader_map.clear
      end
      
      def each
        _map_bootloaders(_central_bootloaders).each do |n|
          yield n, _bootloaders[n]
        end
      end
      
      private
      def _central_bootloaders
        @_central_bootloaders ||= []
      end
      
      def _bootloader_map
        @_bootloader_map ||= Hash.new{|h,k| h[k] = {:before => [], :after => []}}
      end
      
      def _bootloaders
        @_bootloaders ||= {}
      end
      
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