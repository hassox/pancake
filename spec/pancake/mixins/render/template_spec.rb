require 'spec_helper'

describe Pancake::Mixins::Render::Template do
  before do
    $captures = []
    @templates_path = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "fixtures", "render_templates", "templates")
    class ::FooBar
      include Pancake::Mixins::Render
    end
  end
  after do
    clear_constants :FooBar, :BarFoo
  end

  describe "Creation" do
    it "should create a template with a name and a path" do
      result = FooBar::Template.new(:context, FooBar, File.join(@templates_path, "context.erb"))
      result.should_not be_nil
    end

    it "should raise an error when creating a template without a name" do
      lambda do
        FooBar::Template.new(nil, FooBar, File.join(@templates_path, "context.erb"))
      end.should raise_error(Pancake::Mixins::Render::Template::UnamedTemplate)
    end

    it "should raise an error when createing a template withouth a valid file name" do
      lambda do
        FooBar::Template.new(:foo, FooBar, "/not/a/real/file.erb")
      end.should raise_error(Pancake::Mixins::Render::Template::NotFound)
    end

    it "should raise an error when it cannot create a rendering object for the file" do
      lambda do
        FooBar::Template.new(:foo, FooBar, "/not/registed")
      end.should raise_error
    end

    describe "accessing information" do
      before do
        @template = FooBar::Template.new(:context, FooBar, File.join(@templates_path, "context.erb"))
      end

      it "should provide access to it's name" do
        @template.name.should == :context
      end

      it "should provide access to it's path" do
        @template.path.should == File.join(@templates_path, "context.erb")
      end

      it "should render the template" do
        @template.render.should match(/in context/m)
      end

      describe "contexts" do
        before do
          @context = mock("context")
        end

        it "should render with the given context" do
          @template.render(@context)
          $captures.first.should == @context
        end
      end
    end
  end

end
