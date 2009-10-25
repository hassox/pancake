Pancake::Stacks::Short::BootLoader.add(:paths, ) do
  def run!
    stack_class.push_paths :public, "public"

    stack_class::Controller.push_paths :views, ["app/views", "views"], "**/*"
  end
end

Pancake::Stacks::Short::BootLoader.add(:default_middlewares, :before => :load_mounted_inits) do
  def run!
    stack_class.stack(:static_files).use(Pancake::Middlewares::Static, stack_class)
  end
end
