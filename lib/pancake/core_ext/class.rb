class Class
  # Taken from extlib but uses a full Marshall.dump rather than just a dup.
  # This may not work for some data types.  The data must be marshalable to use this method.
  #
  # Defines class-level inheritable attribute reader. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # @param *syms<Array[#to_s]> Array of attributes to define inheritable reader for.
  # @return <Array[#to_s]> Array of attributes converted into inheritable_readers.
  #
  # @api public
  #
  # @todo Do we want to block instance_reader via :instance_reader => false
  # @todo It would be preferable that we do something with a Hash passed in
  #   (error out or do the same as other methods above) instead of silently
  #   moving on). In particular, this makes the return value of this function
  #   less useful.
  def deep_copy_class_inheritable_reader(*ivars)
    instance_reader = ivars.pop[:reader] if ivars.last.is_a?(Hash)

    ivars.each do |ivar|
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{ivar}
          return @#{ivar} if self == #{self} || defined?(@#{ivar})
          ivar = superclass.#{ivar}
          return nil if ivar.nil? && !#{self}.instance_variable_defined?("@#{ivar}")
          @#{ivar} = ivar && !ivar.is_a?(Module) && !ivar.is_a?(Numeric) ? Marshal.load(Marshal.dump(ivar)) : ivar
        end
      RUBY
      unless instance_reader == false
        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{ivar}
            self.class.#{ivar}
          end
        RUBY
      end # unless
    end # ivars.each
  end # self.deep_inheritable_reader
  
  def deep_copy_class_inheritable_accessor(*ivars)
    deep_copy_class_inheritable_reader(*ivars)
    class_inheritable_writer(*ivars)
  end
end # Class