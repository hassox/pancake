require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Mixins::Render do
  before do
    class ::RenderSpecClass
      include Pancake::Mixins::Render

      # setup the renderer
      roots << File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures", "render_templates"))
      push_paths :views, "/", "**/*"

      def params
        @params ||= {}
      end

      def string
        render :text => "A String"
      end

      def the_current_context
        "the current context"
      end
    end

    @render = RenderSpecClass.new
  end
  after do
    clear_constants "RenderSpecClass"
  end

  it "should allow me to render a string" do
    @render.string.should == "A String"
  end

  it "should render a haml" do
    @render.render(:haml_template).chomp.should == "IN HAML"
  end

  it "should render erb" do
    @render.render(:erb_template).should == "IN ERB"
  end

  it "should render an xml format" do
    @render.render(:haml_template, :format => :xml).chomp.should == "IN HAML XML"
  end

  it "should render an erb template for json" do
    @render.render(:erb_template, :format => :json).chomp.should == "IN ERB JSON"
  end

  it "should render with the rendering controller as the current context" do
    @render.render(:context_template).chomp.should == "the current context"
  end

end
