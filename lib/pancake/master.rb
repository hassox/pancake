module Pancake
  # A simple rack application 
  OK_APP = lambda{|e| [200, {"Content-Type" => "text/plain", "Content-Length" => "2"},"OK"]}
  
  class << self
    attr_accessor :root
    
    # Start Pancake.  This results in a rack application to pass to the 
    # rackup file
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
    
    # A helper method to get the expanded directory name of a __FILE__
    # :api: public
    def get_root(file)
      File.expand_path(File.dirname(file))
    end
    
  end # self
end # Pancake