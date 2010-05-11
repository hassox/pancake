module Pancake
  module Errors
    class HttpError < StandardError
      class_inheritable_accessor :error_name, :code, :description

      def name; self.class.name; end

      def code; self.class.code; end
      alias_method :status, :code

      def description; self.class.description; end
    end

    class NotFound < HttpError
      self.error_name = "Not Found"
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
       self.error_name = "Unauthorized"
       self.code = 401
       self.description = "Authentication is required to access this resource."
     end

     class Forbidden < HttpError
       self.error_name = "Forbidden"
       self.code = 403
       self.description = "Access to this resource is denied."
     end

     class Server < HttpError
       attr_accessor :exceptions

       self.error_name = "Server Error"
       self.code = 500
       self.description = "An internal server error"

       def initialize(*args)
         super
         @exceptions = []
       end
     end

     class NotAcceptable < HttpError
       self.error_name =  "Not Acceptable"
       self.code = 406
       self.description = "The requeseted format could not be provided"
     end

  end
end
