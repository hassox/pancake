module Pancake
  # Pancake::Paths provides a mixin for path management.
  # A path consists of a name, and paths + globs, and makes use of the Klass.roots that have been set as
  # file roots for each path and glob to be applied to.
  # Each name may have many (path + glob)s, so that many root paths may be added to the same name
  #
  # @example Adding Paths:
  #   class Foo
  #     extend Pancake::Paths
  #   end
  #
  #   Foo.push_paths(:model, "relative/path/to/models", "**/*.rb")
  #   Foo.push_paths(:model, "another/path/to/models", "**/*.rb")
  #   Foo.push_paths(:model, "yet/another")
  #
  # This will make available the directory and or full file paths for :model in the order they
  # were declared.
  #
  # When no glob is provided, the glob will be returned as nil
  #
  # @example Reading Paths:
  #   Foo.dirs_for(:model) == ["#{root}/relative/path/to/models", "#{root}/another/path/to/models", "#{root}/yet/another"]
  #
  #   Foo.dirs_and_glob_for(:model) == [
  #     ["#{root}/relative/path/to/models",         "**/*.rb"],
  #     ["#{root}/another/path/to/models",         "**/*.rb"],
  #     ["#{root}/yet/another",                    nil]
  #   ]
  #
  #   Foo.paths_for(:model) == [
  #     ["#{root}/relative/path/to/models",   "/model1.rb"],
  #     ["#{root}/path/to/models",            "/model2.rb"],
  #     ["#{root}/path/to/models/sub",        "/model1.rb"],
  #     ["#{root}/another/path/to/models",    "/model3.rb"]
  #   ]
  #
  # The paths are fully inheritable once they have extended a class.
  module Paths
    class NoPathsGiven < ArgumentError; end

    def self.extended(base) #:nodoc:#
      base.class_eval do
        deep_copy_class_inheritable_reader :_load_paths, :roots
        @_load_paths = ActiveSupport::OrderedHash.new
        @roots = []
      end
    end

    # Push a named path and optional glob onto the list of paths associated with <name>
    #
    # @param [Symbol]         name  The name to associate with the given path and glob
    # @param [String, Array]  paths A path or paths to associate with the namd and glob
    # @param [String, Nil]    glob  The glob to associate with the given path(s) and name
    #
    # @example No Glob:
    #   MyClass.push_paths(:foo, "path/for/foo")
    #
    # @example Using a Glob:
    #   MyClass.push_paths(:foo, "path/for/foo", "**/*.rb")
    #
    # @example Using Multiple paths:
    #   MyClass.push_paths(:foo, ["path/one", "path/two"], "**/*.rb")
    #
    # @raise [Pancake::NoPathsGiven] raised when an empty paths array is provided
    # @author Daniel Neighman
    # @since 0.1.1
    # @api public
    def push_paths(name, paths, glob = nil)
      paths = [paths].flatten
      raise NoPathsGiven if paths.blank?
      _load_paths[name] ||= []
      _load_paths[name] << [paths, glob]
    end

    # Provides the directories or raw paths that are associated with a given name.
    #
    # @param        [Symbol]    name  The name for the paths group
    # @param        [Hash]      opts  An options hash
    # @option opts  [Boolean]   :invert (false) inverts the order of the returned paths
    #
    # @example Read Directories:
    #   MyClass.dirs_for(:models)
    #
    # @example Inverted Read:
    #   MyClass.dirs_for(:models, :invert => true)
    #
    # @return [Array] An array of the paths
    #   Returned in declared order unless the :invert option is set
    # @api public
    # @since 0.1.1
    # @author Daniel Neighman
    def dirs_for(name, opts = {})
      if _load_paths[name].blank?
        []
      else
        result = []
        invert = !!opts[:invert]
        load_paths = invert ? _load_paths[name].reverse : _load_paths[name]
        roots.each do |root|
          load_paths.each do |paths, glob|
            paths = paths.reverse if invert
            result << paths.map{|p| File.join(root, p)}
          end
        end
        result.flatten
      end # if
    end

    # Provides the list of paths (directories) and the associated globs for a given name.
    #
    # @param        [Symbol]    name    The name of the path group
    # @param        [Hash]      opts    A hash of options
    # @option opts  [Boolean]   :invert (false) Inverts the order of the paths
    #
    # @example
    #   MyClass.dirs_and_glob_for(:models)
    #
    # @return [Array] An array of [path, glob] arrays
    #   Returned in declared order unless the :invert option is set
    # @api public
    # @since 0.1.1
    # @author Daniel Neighman
    def dirs_and_glob_for(name, opts = {})
      if _load_paths[name].blank?
        []
      else
        result = []
        invert = !!opts[:invert]
        load_paths = invert ? _load_paths[name].reverse : _load_paths[name]
        roots.each do |root|
          load_paths.each do |paths, glob|
            paths = paths.reverse if invert
            paths.each do |path|
              result << [File.join(root, path), glob]
            end # paths.each
          end # load_paths.each
        end # roots.each
        result
      end # if
    end

    # Provides an expanded, globbed list of paths and files for a given name.
    #
    # @param        [Symbol]  name    The name of the paths group
    # @param        [Hash]    opts    An options hash
    # @option opts  [Boolean] :invert (false) Inverts the order of the returned values
    #
    # @example
    #   MyClass.paths_for(:model)
    #   MyClass.paths_for(:model, :invert => true)
    #
    # @return [Array]
    #   An array of [path, file] arrays.  These may be joined to get the full path.
    #   All matched files for [paths, glob] will be returned in declared and then found order unless +:invert+ is true.
    #   Any path that has a +nil+ glob associated with it will be excluded.
    #
    # @api public
    # @since 0.1.1
    # @author Daniel Neighman
    def paths_for(name, opts = {})
      result = []
      dirs_and_glob_for(name, opts).each do |path, glob|
        next if glob.nil?
        paths = Dir[File.join(path, glob)]
        paths = paths.reverse if opts[:invert]
        paths.each do |full_path|
          result << [path, full_path.gsub(path, "")]
        end
      end
      result
    end

    # Provides an expanded, globbed list of paths and files for a given name.
    # The result includes only the last matched file of a given sub path and name.
    #
    # @param        [Symbol]    name    The name of the paths group
    # @param        [Hash]      opts    An options hash
    # @option opts  [Boolean]   :invert (false) Inverts the order of returned paths and files
    #
    # @example
    #   #Given the following:
    #   #  /path/one/file1.rb
    #   #  /path/one/file2.rb
    #   #  /path/two/file1.rb
    #
    #     MyClass.push_path(:files, ["/path/one", "/path/two"], "**/*.rb")
    #
    #   MyClass.unique_paths_for(:files)
    #   MyClass.unique_paths_for(:files, :invert => true)
    #
    # @return [Array]
    #   Returns an array of [path, file] arrays
    #   Results are retuned in declared order.  Only unique files are returned (the file part - the path)
    #   In the above example, the following would be returned for the standard call
    #     [
    #       ["#{root}/path/one", "/file2.rb"],
    #       ["#{root}/path/two", "/file1.rb"]
    #     ]
    #   For the inverted example the following is returned:
    #     [
    #       ["#{root}/path/one/file2.rb"],
    #       ["#{root}/path/one/file1.rb"]
    #     ]
    #
    # @api public
    # @since 0.1.1
    # @author Daniel Neighman
    def unique_paths_for(name, opts = {})
      tally = {}
      output = []
      paths_for(name, opts).reverse.each do |ary|
        tally[ary[1]] ||= ary[0]
        output << ary if tally[ary[1]] == ary[0]
      end
      output.reverse
    end # unique_paths_for
  end
end
