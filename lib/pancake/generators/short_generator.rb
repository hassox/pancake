module Pancake
  module Generators
    class Short < Base
      argument :short_stack, :banner => "Name of stack"
      
      desc "Generates a short stack"
      def stack
        say "Creating The Short Stack For #{short_stack}"
        directory "%short_stack%"
        template  File.join(self.class.source_root, "common/dotgitignore"), "#{short_stack}/.gitignore"
        template  File.join(self.class.source_root, "common/dothtaccess"),  "#{short_stack}/lib/#{short_stack}/public/.htaccess"
      end
       
       
    end
  end
end
