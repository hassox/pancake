require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Pancake::Mixins::Render::ViewContext do
  
  before do
    $captures = []
    class ::FooBar
      include Pancake::Mixins::Render
      attr_accessor :params, :data

      def _template_name_for(name, opts)
        "#{name}"
      end
      push_paths :views, "", "**/*"
      
      roots << File.join(File.expand_path(File.dirname(__FILE__)),"..","..", "fixtures", "render_templates", "view_context")
    end
  end

  after do
    clear_constants :FooBar, :BarFoo
  end

  it "should setup the spec correctly" do
    %w(helper_methods.erb context.erb).each do |f|
      File.exists?(File.join(FooBar.roots.first, f)).should be_true
    end
  end

  describe "view contexts" do

    it "should use the view context object" do
      result = FooBar.new.render(:context)
      
      result.should_not be_nil
      result.should match(/in view_context/mi)
    end

    it "should use the view context object as the rendering object" do
      result = FooBar.new.render(:context)
      result.should match(/ViewContext/m)
      $captures.first.class.should == FooBar::ViewContext
    end

    it "should inherit from Pancake::Mixins::Render::ViewContext" do
      FooBar::ViewContext.should inherit_from(Pancake::Mixins::Render::ViewContext)
    end
    

    it "should allow me to setup the view context before the view is run" do
      FooBar.class_eval do
        def view_context_before_render(context)
          super
          $captures << :here
        end
      end
      $captures.should be_blank
      FooBar.new.render(:context)
      $captures.should include(:here)
    end

    it "should execute the before render block in the instance" do
      FooBar.class_eval do
        def view_context_before_render(context)
         super
          $captures << data
        end
      end
      foobar = FooBar.new
      foobar.data = {:some => :data}
      foobar.render(:context)
      $captures.should include(:some => :data)
      $captures.clear
      FooBar.new.render(:context)
      $captures.should_not include(:some => :data)
    end
  end

  describe "inheriting classes" do
    before do
      FooBar::ViewContext.class_eval do
        def some_helper
          $captures << :some_helper
        end
      end

      class ::BarFoo < FooBar
      end
      
    end
    
    it "should inherit the view context when inheriting the outer class" do
      BarFoo::ViewContext.should inherit_from(FooBar::ViewContext)
    end

    it "should make FooBar's helpers available to BarFoo" do
      $captures.should be_blank
      result = BarFoo.new.render(:helper_methods)
      $captures.should include(:some_helper)
    end
    
  end

  describe "delegation" do
    it "should provide access to the object the view context is rendering for" do
      FooBar.new.render(:context)
      context = $captures.first
      context.should_not be_nil
      context.should be_a_kind_of(FooBar::ViewContext)
      context.view_context_for.should be_an_instance_of(FooBar)
    end
    
    it "should render from the callee when calling render inside a template" do
      foo = FooBar.new
      result = foo.render(:nested_outer)
      result.should match(/outer template.*?inner template/mi)
    end
  end

  describe "template context sub-classing" do
    it "should have different sub classes for different templates" do
      foo = FooBar.new
      foo.render(:context)
      context1 = $captures.pop
      foo.render(:context2)
      context2 = $captures.pop
      context1.should be_a_kind_of(FooBar::ViewContext)
      context2.should be_a_kind_of(FooBar::ViewContext)
      context1.class.should_not == context2.class
    end
    
  end
  
end




