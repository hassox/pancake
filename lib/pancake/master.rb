module Pancake
  # A simple rack application 
  OK_APP      = lambda{|e| [200, {"Content-Type" => "text/plain", "Content-Length" => "2"},"OK"]}
  MISSING_APP = lambda{|e| [404, {"Content-Type" => "text/plain", "Content-Length" => "9"},"NOT FOUND"]}
  
  extend Middleware
  
  class << self
    attr_accessor :root
    
    # Start Pancake.  This results in a rack application to pass to the 
    # rackup file
    def start(opts, &block)
      raise "You must specify a root directory for pancake" unless opts[:root]
      self.root = opts[:root]
      
      # initialize the application
      load "#{root}/pancake.init"
      
      # Build Pancake
      the_app = instance_eval(&block)
      Pancake::Middleware.build(the_app, middlewares)
    end
    
    def env
      ENV['RACK_ENV'] ||= "development"
    end
    
    # A helper method to get the expanded directory name of a __FILE__
    # :api: public
    def get_root(file)
      File.expand_path(File.dirname(file))
    end
  
    def stack_labels
      return @stack_labels unless @stack_labels.nil? || @stack_labels.empty?
      self.stack_labels = [:production]
    end
    
    def stack_labels=(*labels)
      @stack_labels = labels.flatten.compact
    end
    
  end # self
end # Pancake