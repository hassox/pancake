module Pancake
  module Paths
    class NoPathsGiven < ArgumentError; end
    class NoRootsGiven < ArgumentError; end
    
    def self.extended(base)
      base.class_eval do
        class_inheritable_accessor :_load_paths
        self._load_paths = Dictionary.new
      end
    end
    
    def push_path(name, roots, glob = nil)
      roots = [roots].flatten
      raise NoRootsGiven if roots.blank?
      _load_paths[name] ||= []
      _load_paths[name] << [roots, glob]
    end
    
    def dirs_for(name, opts = {})
      if _load_paths[name].blank?
        []
      else
        result = []
        reverse = !!opts[:reverse]
        load_paths = reverse ? _load_paths[name].reverse : _load_paths[name]
        load_paths.each do |roots, glob|
          roots = roots.reverse if reverse
          result << roots
        end
        result.flatten
      end # if 
    end
    
    def dirs_and_glob_for(name, opts = {})
      if _load_paths[name].blank?
        []
      else
        result = []
        reverse = !!opts[:reverse]
        load_paths = reverse ? _load_paths[name].reverse : _load_paths[name]
        load_paths.each do |roots, glob|
          roots = roots.reverse if reverse
          roots.each do |root| 
            result << [root, glob]
          end # roots.each
        end # _load_paths[name].each
        result
      end # if
    end
    
    # Gets the paths of files.  If a relative file exists in multiple roots, the last one will
    # be returned
    # Example
    #
    #   root1
    #    - file1.rb
    #    - file2.rb
    #    - file3.rb
    #   root2
    #    - file2.rb
    #
    # MyApp.push_path(:files, "root1", "**/*.rb")
    # MyApp.push_path(:files, "root2", "**/*.rb")
    #
    # MyApp.paths_for(:files) == [
    #   "root1/file1.rb",
    #   "root1/file3.rb",
    #   "root2/file2.rb"
    # ]
    #
    # The above push_path could have been written as
    # MyApp.push_path(:files, ["root1","root2"])
    #
    # @api public
    def paths_for(name, opts = {})
      result = {}
      output = []
      load_paths = opts[:reverse] ? _load_paths[name].reverse : _load_paths[name] 
      # Get each file - root and root
      load_paths.each do |roots, glob|
        next if glob.nil?
        # reverse the roots if they should be reversed
        roots = roots.reverse if opts[:reverse]
        roots.each do |root|
          # Put the returned files into a hash keyed on the file path
          # this way, as we go, new root paths will overwrite old ones for the same file
          Dir[File.join(root, glob)].each do |full_path|
            result[full_path.gsub(root, "")] = root
          end #Dir.each
        end #roots.each
      end # _load_paths[name].each
      result.each do |file, root|
        output << File.join(root, file)
      end
      output
    end # paths_for
  end
end