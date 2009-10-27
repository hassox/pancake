module Pancake
  module Mixins
    module ResponseHelper
      def headers
        @headers ||= {}
      end

      def status
        @status ||= 200
      end

      def status=(st)
        @status = st
      end

      def redirect(location, status = 302)
        r = Rack::Response.new
        r.redirect(location, status)
        r
      end
    end
  end
end
