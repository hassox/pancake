module Pancake
  module Stacks
    class Short < Pancake::Stack

      def self.new_app_instance
        self::Controller
      end

      # Marks a method as published.
      # This is done implicitly when using the get, post, put, delete methods on a Stacks::Short
      # But can be done explicitly
      #
      # @see Pancake::Mixins::Publish#publish
      # @api public
      def self.publish(*args)
        @published = true
        self::Controller.publish(*args)
      end

      # @see Pancake::Mixins::Publish#as
      def self.as(*args)
        self::Controller.as(*args)
      end

      # @see Pancake::Mixins::Publish#provides
      def self.provides(*formats)
        self::Controller.provides(*formats)
      end

      def self.handle_exception(*args, &block)
        self::Controller.handle_exception(*args, &block)
      end

      # Gets a resource at a given path
      #
      # The block should finish with the final result of the action
      #
      # @param [String] path  - a url path that conforms to Rack::Router match path.
      # @param block - the contents of the block are executed when the path is matched.
      #
      # @example
      #   get "/posts(/:year(/:month(/:date))" do
      #     # do stuff to get posts and render them
      #   end
      #
      # @see Rack::Router
      # @api public
      # @author Daniel Neighman
      def self.get(path, opts = {}, &block)
        define_published_action(:get, path, opts, block)
      end

      # Posts a resource to a given path
      #
      # The block should finish with the final result of the action
      #
      # @param [String] path - a url path that conforms to Rack::Router match path.
      # @param block - the contents of the block are executed when the path is matched.
      #
      # @example
      #   post "/posts" do
      #     # do stuff to post  /posts and render them
      #   end
      #
      # @see Rack::Router
      # @api public
      # @author Daniel Neighman
      def self.post(path, opts = {}, &block)
        define_published_action(:post, path, opts,  block)
      end

      # Puts a resource to a given path
      #
      # The block should finish with the final result of the action
      #
      # @param [String] path - a url path that conforms to Rack::Router match path.
      # @param block - the contents of the block are executed when the path is matched.
      #
      # @example
      #   put "/posts" do
      #     # do stuff to post  /posts and render them
      #   end
      #
      # @see Rack::Router
      # @api public
      # @author Daniel Neighman
      def self.put(path, opts = {}, &block)
        define_published_action(:put, path, opts, block)
      end

      # Deletes the resource at a given path
      #
      # The block should finish with the final result of the action
      #
      # @param [String] path - a url path that conforms to Rack::Router match path.
      # @param block - the contents of the block are executed when the path is matched.
      #
      # @example
      #   delete "/posts/foo-is-post" do
      #     # do stuff to post foo-is-post and render the result
      #   end
      #
      # @see Rack::Router
      # @api public
      # @author Daniel Neighman
      def self.delete(path, opts = {}, &block)
        define_published_action(:delete, path, opts, block)
      end

      private
      # Defines an action on the inner Controller class of this stack.
      # Also sets it as published if it's not already published.
      #
      # @param [Symbol] method - a smbol specifying the HTTP method
      # @param [String] path - a string specifying the path to map the url to
      # @api private
      # @author Daniel Neighman
      def self.define_published_action(method, path, opts, block)
        self::Controller.publish unless @published
        @published = nil

        action_name = next_action_name(method,path)
        attach_action(action_name, block)

        attach_route(method, path, action_name, opts)
      end

      # Does the work of actually defining the action on the Controller Class
      #
      # @param [String] - the name of the method to create on the Controller class
      # @api private
      # @author Daniel Neighman
      def self.attach_action(method_name, block)
        self::Controller.class_eval do
          define_method(method_name, &block)
        end
      end

      # Supplies the path as a route to the stack router
      #
      # @param method [Symbol]
      #
      # @example
      #   attach_route(:get, "/foo/bar", "get_00001__foo_bar")
      #
      # @api private
      # @author Daniel Neighman
      def self.attach_route(method, path, action_name, options)
        name = options.delete(:_name)
        options[:conditions] ||= {}
        options[:conditions][:request_method] = method.to_s.upcase
        options[:default_values] ||= {}
        options[:default_values][:action] = action_name
        options[:_exact] = true unless options[:_exact] == false
        r = router.add(path, options)
        r.name(name) if name
        r
      end

      # provides for methods of the following form on Controller
      #   :<method>_<number>_<sanitized_path>
      # where <number> is incremented
      #
      # @param [Symbol] method - the HTTP method to look for
      # @param [String] path - the url path expression to encode into the method name
      #
      # @return [String] - The next method name to use that won't clash with previously configured actions
      #
      # @api private
      # @author Daniel Neighman
      def self.next_action_name(method, path)
        last = self::Controller.public_instance_methods.grep(%r[#{method}_\d+]).sort.reverse.first
        next_method = 0
        unless last.nil?
          last =~ %r[#{method}_(\d+)]
          next_method = $1
        end
        sprintf("#{method}_%04d_#{sanitize_path(path)}", next_method)
      end

      # sanitizes a path so it's able to be used as a method name
      #
      # @param [String] path - the path to sanitize
      #
      # @return [String] the sanitized version of the path safe to use as a method name
      # @api private
      # @author Daniel Neighman
      def self.sanitize_path(path)
        path.gsub(/\W/, "_")
      end

    end # Short
  end # Stacks
end # Pancake
