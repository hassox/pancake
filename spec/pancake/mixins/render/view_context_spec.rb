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

    it "should inherit from Pancake::Mixins::Render::ViewContext" do
      FooBar::ViewContext.should inherit_from(Pancake::Mixins::Render::ViewContext)
    end

    #it "should allow me to setup the view context before the view is run" do
    #  FooBar.class_eval do
    #    def view_context_before_render(context)
    #      super
    #      $captures << :here
    #    end
    #  end
    #  $captures.should be_blank
    #  FooBar.new.render(:context)
    #  $captures.should include(:here)
    #end

    #it "should execute the before render block in the instance" do
    #  FooBar.class_eval do
    #    def view_context_before_render(context)
    #     super
    #      $captures << data
    #    end
    #  end
    #  foobar = FooBar.new
    #  foobar.data = {:some => :data}
    #  foobar.render(:context)
    #  $captures.should include(:some => :data)
    #  $captures.clear
    #  FooBar.new.render(:context)
    #  $captures.should_not include(:some => :data)
    #end
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
      context = FooBar::ViewContext.new(@renderer)
      context._view_context_for.should == @renderer
    end

    it "should grab the template from the view context when rendering" do
      context = FooBar::ViewContext.new(@renderer)
      @renderer.should_receive(:template).with(:foo).and_return(@renderer)
      context.render(:foo, :some => :opts)
    end
  end

  describe "capturing" do
    before do
    end

    it "should render the haml template with a capture" do
      result = FooBar.new.render(:capture_haml)
      result.should_not include("captured haml")

      context = $captures.first
      context.should_not be_nil
      context.instance_variable_get("@captured_haml").should include("captured haml")
    end

    it "should capture in erb" do
      result = FooBar.new.render(:capture_erb)
      result.should_not include("captured erb")
      context = $captures.first
      context.should_not be_nil
      context.instance_variable_get("@captured_erb").should include("captured erb")
    end

    it "should concat in haml" do
      result = FooBar.new.render(:concat_haml)
      result.should include("concatenated")
    end

    it "should concat in erb" do
      result = FooBar.new.render(:concat_erb)
      result.should include("concatenated")
    end
  end

  describe "content_block" do
    before do
      @foo = FooBar.new
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

  %w(haml).each do |type|
    describe "inheritable #{type} views" do
      it "should inherit #{type} from within #{type}" do
      end
    end
  end

end




