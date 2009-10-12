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
    end
  end
end
