require 'set'
module Pancake
  module BootLoaderMixin
    include Enumerable
    class Base
      # :api: :public
      attr_accessor :config

      # Sets options for the bootloder
      # By including conditions in the bootloader when you declare it
      # You can selectively run bootloaders later
      # :api: private
      def self.options=(opts={}) # :nodoc:
        @options = opts
        @options[:level] ||= :default
      end

      # Provides access to the bootloader options
      # :api: private
      def self.options # :nodoc:
        @options ||= {}
      end

      def stack
        raise "No Stack Configured" unless @config[:stack]
        @config[:stack]
      end

      def stack_class
        raise "No Stack Class Configured" unless @config[:stack_class]
        @config[:stack_class]
      end

      def initialize(config)
        @config = config
      end

      # Creates a new instance and runs it
      # :api: private
      def self.call(config)
        new(config).run!
      end

      # Checks the conditions with the options of the bootloader
      # To see if this one should be run
      # Only the central bootloaders with the conditions will be checked
      # :api: private
      def self.run?(conditions = {})
        opts = options
        if conditions.keys.include?(:only)
          return conditions[:only].all?{|k,v| opts[k] == v}
        end
        if conditions.keys.include?(:except)
          return conditions[:except].all?{|k,v| opts[k] != v}
        end
        true
      end
    end

    def self.extended(base)
      base.class_eval do
        class_inheritable_reader :_bootloaders, :_central_bootloaders, :_bootloader_map
        @_bootloaders, @_central_bootloaders = {}, []
        @_bootloader_map = Hash.new{|h,k| h[k] = {:before => [], :after => []}}
      end
    end

    # Provides access to an individual bootloader
    # :api: public
    def [](name)
      _bootloaders[name]
    end

    # Provides removal of a bootloader, by replacing it as an empty lambda
    # :api: public
    def delete(name)
      !!self[name] && _bootloaders[name] = lambda{}
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
      _bootloaders[name] = Class.new(Pancake::BootLoaderMixin::Base, &block)
      raise "You must declare a #run! method on your bootloader" unless _bootloaders[name].method_defined?(:run!)
      before = opts[:before]
      after  = opts[:after]

      if opts[:level]
        levels << opts[:level]
        levels.uniq!
      end

      # If there are no before or after keys, add it to the central bootloaders
      if before
        _bootloader_map[before][:before] << name
      elsif after
        _bootloader_map[after][:after] << name
      else
        _central_bootloaders << name unless _central_bootloaders.include?(name)
      end
      _bootloaders[name].options = opts
      _bootloaders[name]
    end

    # Runs the bootloaders in order
    # :api: private
    def run!(options = {}) # :nodoc:
      unless options.keys.include?(:only) || options.keys.include?(:except)
        options[:only] = {:level => :default}
      end
      conditions = if options[:only]
        {:only => options.delete(:only)}
      else
        {:except => options.delete(:except)}
      end
      options[:stack_class] ||= stack

      each(conditions) do |name, bl|
        bl.call(options)
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
      @stack ||= Object.full_const_get(self.name.split("::")[0..-2].join("::"))
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
    def each(conditions = {})
      _map_bootloaders(_central_bootloaders, conditions).each do |n|
        yield n, _bootloaders[n]
      end
    end

    private
    # Map out the bootloaders by name to run.
    # :api: private
    def _map_bootloaders(*names)
      conditions = Hash === names.last ? names.pop : {}
      names.flatten.map do |name|
        if _bootloaders[name].run?(conditions)
          r = []
          r << _map_bootloaders(_bootloader_map[name][:before])
          r << name
          r << _map_bootloaders(_bootloader_map[name][:after])
        end
      end.flatten.compact
    end

    def levels
      @levels ||= [:default]
    end

  end # BootLoaders
end # Pancake
