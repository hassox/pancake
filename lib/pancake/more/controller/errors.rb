module Pancake
  module Errors
    class HttpError < StandardError
      class_inheritable_accessor :name, :code, :description
    end
    
    class NotFound < HttpError
      name = "Not Found"
      code = 404
      description = "The requested resource could not be found but may be available again in the future."
    end
        
     class Unauthorized < HttpError
       name = "Unauthorized"
       code = 401
       description = "Authentication is required to access this resource."
     end
     
     class Forbidden < HttpError
       name = "Forbidden"
       code = 403
       description = "Access to this resource is denied."
     end
  end
end
