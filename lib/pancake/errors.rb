module Pancake
  module Errors
    class HttpError < StandardError
      class_inheritable_accessor :name, :code, :description
    end
    
    class NotFound < HttpError
      self.name = "Not Found"
      self.code = 404
      self.description = "The requested resource could not be found but may be available again in the future."
    end

    class UnknownRouter < NotFound
      self.description = "The router could not be found"
    end
    
    class UnknownConfiguration < NotFound
      self.description = "The configuration could not be found"
    end
        
     class Unauthorized < HttpError
       self.name = "Unauthorized"
       self.code = 401
       self.description = "Authentication is required to access this resource."
     end
     
     class Forbidden < HttpError
       self.name = "Forbidden"
       self.code = 403
       self.description = "Access to this resource is denied."
     end

     class Server < HttpError
       self.name = "Server Error"
       self.code = 500
       self.description = "An internal server error"
     end
     
  end
end
