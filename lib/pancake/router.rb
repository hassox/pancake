module Pancake
  class RouteBuilder < Rack::Router::Builder::Simple
    
    # Use this to mount a rack application in the URL namesapce
    # :api: public
    def mount(path, app, with = {}, conditions = {})
      map path, :to => app, :with => with, :conditions => conditions
    end
    
    # Use this to mount a rails applciation at a giving path
    # You can only mount one rails application since rails is not namespaced
    # :api: public
    def mount_rails(path, with = {}, conditions = {})
      if Rails.version =~ /^2\.3/
        ::ActionController::Base.relative_url_root = path
        app = ::ActionController::Dispatcher.new($stdout)
      else
        raise "Rails version unsupported"
      end
      map path, :to => app, :with => with, :conditions => conditions
    end
    
  end # RouteBuilder
end # Pancake 