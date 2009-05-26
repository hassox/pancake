## Add the router to the new application stack
Pancake::Stack.on_inherit do |base, parent|
  base.class_eval do
    class self::Router
      extend ::Rack::Router::Routable
    end  
  end
end # Pancake::Stack.on_inherit