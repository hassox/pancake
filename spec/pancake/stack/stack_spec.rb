require File.dirname(__FILE__) + '/../../spec_helper'

describe "Pancake::Stack" do
  before(:each) do
    class ::StackSpecStack < Pancake::Stack; end
    class ::OtherSpecStack < Pancake::Stack; end
    StackSpecStack.roots.clear
  end

  after(:each) do
    clear_constants(:StackSpecStack, :FooSpecStack, :OtherSpecStack)
  end

  describe "roots" do

    it "should provide access to setting the roots" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << File.expand_path(File.dirname(__FILE__))
      StackSpecStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end

    it "should provide access to adding a root" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end

    it "should allow me to get multiple roots in the order they're added" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots << "/tmp"
      StackSpecStack.roots.should == [Pancake.get_root(__FILE__), "/tmp"]
    end

    it "should iterate over the roots in the direction they're added" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots << "/foo"
      StackSpecStack.roots.map{|f| f}.should == [Pancake.get_root(__FILE__), "/foo"]
    end

    it "should allow me to set a root with a file" do
      StackSpecStack.add_root(__FILE__)
      StackSpecStack.roots.should include(Pancake.get_root(__FILE__))
    end
  end # roots

  # describe "initialize stack" do

    it "should mark a stack as initialized once it has called the initialize_stack method" do
      StackSpecStack.roots << ::Pancake.get_root(__FILE__)
      StackSpecStack.initialize_stack
      StackSpecStack.should be_initialized
    end

    it "should not be initialized when it has not called initialize_stack" do
      StackSpecStack.should_not be_initialized
    end

    describe "include pancake stack" do
      before do
        $captures = []
        clear_constants(:GeneralMiddleware, :MySpecStack)
        Pancake::StackMiddleware.reset!

        class ::GeneralMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            $captures << self.class
            @app.call(env)
          end
        end
        Pancake.stack(:general).use(GeneralMiddleware)
      end

      it "should let me tell the stack to include the pancake stack" do
        lambda do
          StackSpecStack.include_pancake_stack!
        end.should_not raise_error
      end

      it "should remember that I told it to include the pancake stack" do
        StackSpecStack.include_pancake_stack!
        StackSpecStack.include_pancake_stack?.should be_true
      end

      it "should not remember when inherited" do
        StackSpecStack.include_pancake_stack!
        class ::MySpecStack < StackSpecStack; end
        MySpecStack.include_pancake_stack?.should be_false
      end

      it "should build the stack with the pancake stack out front" do
        StackSpecStack.roots << Pancake.get_root(__FILE__)
        StackSpecStack.include_pancake_stack!
        stack = StackSpecStack.stackup
        stack.should be_an_instance_of(GeneralMiddleware)
      end
    end

    describe "master stack" do
      before do
        @b4 = Pancake.master_stack
      end

      after do
        Pancake.master_stack = @b4
      end

      it "should set the stack to be master, and include the master dir in each root" do
        StackSpecStack.add_root(__FILE__)
        before_roots = StackSpecStack.roots.dup
        s = StackSpecStack.stackup(:master => true)
        before_roots.each do |r|
          StackSpecStack.roots.should include(File.join(r, "master"))
        end
        Pancake.master_stack.should == StackSpecStack
      end

      it "should not set a master stack when one has already been set" do
        StackSpecStack.add_root(__FILE__)
        OtherSpecStack.add_root(__FILE__)
        StackSpecStack.stackup(:master => true)
        Pancake.master_stack.should == StackSpecStack
        OtherSpecStack.stackup(:master => true)
        Pancake.master_stack.should == StackSpecStack
      end
    end

    describe "loading rake tasks" do
      before do
        $captures = []
        StackSpecStack.add_root(__FILE__, "..", "fixtures", "tasks", "root1")
      end

      it "should load the rake tasks in the stacks root" do
        StackSpecStack.load_rake_tasks!
        $captures.should == ["root1/tasks/task1.rake", "root1/tasks/task2.rake"]
      end

      it "should load the rake tasks in order of the roots" do
        StackSpecStack.add_root(__FILE__, "..", "fixtures", "tasks", "root2")
        StackSpecStack.load_rake_tasks!
        $captures.should == [
          "root1/tasks/task1.rake",
          "root1/tasks/task2.rake",
          "root2/tasks/task1.rake",
          "root2/tasks/task2.rake"
        ]
      end

      it "should load rake tasks for mounted applications" do
        class ::FooSpecStack < Pancake::Stack
          add_root(__FILE__, "..", "fixtures", "tasks", "root2")
        end
        StackSpecStack.router.mount(FooSpecStack, "/foo")
        StackSpecStack.load_rake_tasks!
        # Mounted stacks should have their rake tasks loaded first so they can be overwritten
        $captures.should == [
          "root2/tasks/task1.rake",
          "root2/tasks/task2.rake",
          "root1/tasks/task1.rake",
          "root1/tasks/task2.rake"
        ]
      end

      it "should not try to load rake tasks of a mounted app that does not respond to load_rake_tasks!" do
        class ::FooSpecStack < Object
          def self.call(env); Rack::Response.new("OK").finish; end
        end
        StackSpecStack.router.mount(FooSpecStack, "/foo/spec")
        lambda do
          StackSpecStack.load_rake_tasks!
        end.should_not raise_error
      end
    end
end
