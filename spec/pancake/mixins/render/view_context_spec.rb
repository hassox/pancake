require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Pancake::Mixins::Render::ViewContext do

  before do
    @masters = [Pancake.master_stack, Pancake.master_templates]
    $captures = []
    class ::FooBar
      include Pancake::Mixins::Render
      attr_accessor :params, :data

      def initialize(env)
        @env = env
      end

      def self._template_name_for(name, opts)
        "#{name}"
      end

      push_paths :views, "", "**/*"

      roots << File.join(File.expand_path(File.dirname(__FILE__)),"..","..", "fixtures", "render_templates", "view_context")
    end
    Pancake.master_stack = FooBar
    Pancake.master_templates = FooBar
  end

  after do
    Pancake.master_stack, Pancake.master_templates = @masters
    clear_constants :FooBar, :BarFoo
  end

  it "should setup the spec correctly" do
    %w(helper_methods.erb context.erb).each do |f|
      File.exists?(File.join(FooBar.roots.first, f)).should be_true
    end
  end

  describe "view contexts" do

    it "should inherit from Pancake::Mixins::Render::ViewContext" do
      FooBar::ViewContext.should inherit_from(Pancake::Mixins::Render::ViewContext)
    end

    it "should include the Pancake::Mixins::RequestHelper helper" do
      (Pancake::Mixins::RequestHelper > FooBar::ViewContext).should be_true
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
  end

  describe "delegation" do
    before do
      @renderer = mock("renderer", :null_object => true)
    end

    it "should provide access to the object the view context is rendering for" do
      context = FooBar::ViewContext.new({}, @renderer)
      context._view_context_for.should == @renderer
    end

    it "should grab the template from the view context when rendering" do
      context = FooBar::ViewContext.new({}, @renderer)
      @renderer.should_receive(:template).with(:foo).and_return(@renderer)
      context.render(:foo, :some => :opts)
    end
  end

  describe "capturing" do
    before do
    end

    it "should render the haml template with a capture" do
      result = FooBar.new({}).render(:capture_haml)
      result.should_not include("captured haml")

      context = $captures.first
      context.should_not be_nil
      context.instance_variable_get("@captured_haml").should include("captured haml")
    end

    it "should capture in erb" do
      result = FooBar.new({}).render(:capture_erb)
      result.should_not include("captured erb")
      context = $captures.first
      context.should_not be_nil
      context.instance_variable_get("@captured_erb").should include("captured erb")
    end

    it "should concat in haml" do
      result = FooBar.new({}).render(:concat_haml)
      result.should include("concatenated")
    end

    it "should concat in erb" do
      result = FooBar.new({}).render(:concat_erb)
      result.should include("concatenated")
    end
  end

  describe "content_block" do
    before do
      @foo = FooBar.new({})
    end

    it "should include the default text" do
      result = @foo.render(:inherited_haml_level_0)
      result.should include("inherited haml level 0")
      result.should include("default content block content")
    end

    it "should inherit the content block from a parent template" do
      result = @foo.render(:inherited_haml_level_1)
      result.should include("inherited haml level 0")
      result.should include("inherited haml level 1 content")
    end

    it "should inherit the default text in erb" do
      result = @foo.render(:inherited_erb_level_0)
      result.should include("inherited erb level 0")
      result.should include("default content block content")
    end

    it "should inherit the content block from a parent template in erb" do
      result = @foo.render(:inherited_erb_level_1)
      result.should include("inherited erb level 0")
      result.should include("inherited erb level 1 content")
    end

    it "should inherit erb from haml" do
      result = @foo.render(:inherited_erb_from_haml)
      result.should include("inherited haml level 0")
      result.should include("inherited erb content")
    end

    it "should inherit haml from erb" do
      result = @foo.render(:inherited_haml_from_erb)
      result.should include("inherited erb level 0")
      result.should include("inherited haml content")
    end

  end

  describe "super blocks" do
    before do
      @foo = FooBar.new({})
    end

    it "should render the super text" do
      result = @foo.render(:super_haml_from_haml_0)
      result.should include("default content block content")
    end

    it "should render the super text and the new text" do
      result = @foo.render(:super_haml_from_haml_1)
      result.should include("default content block content")
      result.should include("new content with super")
    end

    it "should render the super text in erb templates" do
      result = @foo.render(:super_erb_from_erb_0)
      result.should include("default content block content")
    end

    it "should render the super text and the new text in erb" do
      result = @foo.render(:super_erb_from_erb_1)
      result.should include("new content with super")
      result.should include("default content block content")
    end

    it "should inherit haml from erb" do
      result = @foo.render(:super_haml_from_erb_0)
      result.should include("default content block content")
    end

    it "should inherit haml from erb with with additional contnet" do
      result = @foo.render(:super_haml_from_erb_1)
      result.should include("new content from haml")
      result.should include("default content block content")
    end

    it "should inherit erb from haml" do
      result = @foo.render(:super_erb_from_haml_0)
      result.should include("default content block content")
    end

    it "should inherit erb from haml" do
      result = @foo.render(:super_erb_from_haml_1)
      result.should include("new content from erb")
      result.should include("default content block content")
    end
  end

  describe "multiple context blocks" do
    before do
      @foo = FooBar.new({})
    end

    it "should allow nested default captures" do
      result = @foo.render(:nested_content_level_0)
      result.should include("level 0 content")
      result.should include("nested foo content")
      result.should include("nested bar content")
    end

    it "should allow inherited nested content to overwrite a given block" do
      result = @foo.render(:nested_content_level_1)
      result.should include("level 0 content")
      result.should include("nested foo content")
      result.should include("nested new bar content")
    end
  end

  describe "inheriting from a template object" do
    before do
      path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..",  "fixtures", "render_templates", "inherit"))

      class ::BarFoo
        include Pancake::Mixins::Render
        push_paths :views, "", "**/*"
      end

      class ::FooBar
        def self._template_name_for(name, opts = {})
          opts[:format] ||= :html
          r = "#{name}.#{opts[:format]}"
        end
      end

      FooBar.roots << File.join(path, "foo")
      BarFoo.roots << File.join(path, "bar")
      @app = FooBar.new({})
      @bar = BarFoo.new
      Pancake.master_templates = BarFoo
    end

    it "should inherit from it's own stack with a name" do
      result = @app.render(:simple)
      result.should include("Foo Base")
      result.should include("Simple Foo Content")
    end

    it "should inherit from a stack, name pair" do
      result = @app.render(:explicit)
      result.should include("Bar Layout")
      result.should include("Explicit Content")
    end

    it "should inherit from the pancake default using :defaults!" do
      result = @app.render(:defaults)
      result.should include("Bar Base")
      result.should include("Defaults Content")
    end

    it "should use it's own base template when pancake does not have one set" do
      Pancake.master_templates = nil
      result = @app.render(:defaults)
      result.should include("Foo Base")
      result.should include("Defaults Content")
    end

  end

  describe "partials" do
    before do
      @foo = FooBar.new({})
      @collection = %w(one two three four)
      $captures = []
    end

    it "should use the _partial_template_name_for method to find a partial" do
      @foo.should_receive(:_partial_template_name_for).with(:basic, {}).and_return("_basic")
      result = @foo.partial(:basic)
    end

    it "should render a partial with the partial call" do
      result = @foo.partial(:basic)
      result.should include("In Partial Basic")
    end

    it "should render from within a template" do
      result = @foo.render(:contains_partial)
      result.should include("In Partial Basic")
    end

    it "should use a different view context instance for the partial" do
      result = @foo.render(:contains_partial)
      $captures.should have(2).items
      $captures.first.should_not == $captures.last
    end

    it "should allow me to specify locals for use in the partial" do
      result = @foo.partial(:with_locals, :foo => "this is foo", :bar => "and this is bar")
      result.should include("foo == this is foo")
      result.should include("bar == and this is bar")
    end

    it "should render a partial with an object as the local name" do
      result = @foo.partial(:local_as_name, :with => "value of local as name")
      result.should include("local_as_name == value of local as name")
    end

    it "should render a partial with many objects with the obj as a local with the partial name" do
      result = @foo.partial(:local_as_name, :with => @collection)
      @collection.each do |val|
        result.should include("local_as_name == #{val}")
      end
    end

    it "should render a partial with an object with a specified name" do
      result = @foo.partial(:foo_as_name, :with => "jimmy", :as => :foo)
      result.should include("foo == jimmy")
    end

    it "should render a partial with many objects as a local with a specified name" do
      result = @foo.partial(:foo_as_name, :with => @collection, :as => :foo)
      @collection.each do |val|
        result.should include("foo == #{val}")
      end
    end

  end
end




