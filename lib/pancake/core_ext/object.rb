class Object
  extend ::Pancake::Hooks::InheritableInnerClasses
end

# Vendored from http://eigenclass.org/hiki/instance_exec
# 2009-06-02
# Adapted for ruby 1.9 where the method is deinfed on Object
unless Object.method_defined?(:instance_exec)
  class Object
   # Like instace_eval but allows parameters to be passed.
    def instance_exec(*args, &block)
      mname = "__instance_exec_#{Thread.current.object_id.abs}_#{object_id.abs}"
      Object.class_eval{ define_method(mname, &block) }
      begin
        ret = send(mname, *args)
      ensure
        Object.class_eval{ undef_method(mname) } rescue nil
      end
      ret
    end
  end
end
