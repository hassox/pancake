module Pancake
  
  class << self
    attr_accessor :root
    
    def start(opts)
      puts "Starting Pancake"
      raise "You must specify a root directory for pancake" unless opts[:root]
      self.root = opts[:root]
      
      # initialize the application
      load "#{root}/pancake.init"
      
      Pancake::Router
    end
    
  end # self
end # Pancake