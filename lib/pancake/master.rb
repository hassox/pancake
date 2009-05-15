module Pancake
  
  class << self
    attr_accessor :root
    
    def start(opts)
      puts "Starting Pancake"
      raise "You must specify a root directory for pancake" unless opts[:root]
      self.root = opts[:root]
      
      # initialize the application
      load "#{root}/pancake.init"
      
      # Build Pancake
      Rack::Builder.new do
        run Pancake::Router
      end
    end
    
    def mount(&block)
      Pancake::Router.prepare(&block)
    end
    
    def env
      ENV['RACK_ENV'] ||= "development"
    end
    
  end # self
end # Pancake