module Pancake
  module Generators
    class Base < Thor::Group
      include Thor::Actions
      
      def self.source_root
        File.join(File.dirname(__FILE__), "templates")
      end
      
    end
  end
end