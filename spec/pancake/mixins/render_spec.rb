require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Mixins::Render do
  before do
    class ::RenderSpecClass
      include Pancake::Mixins::Render

      # setup the renderer
      roots << File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures", "render_templates"))
      push_paths :views, "/", "**/*"

      def self._template_name_for(name, opts = {})
        opts[:format] ||= :html
        "#{name}.#{opts[:format]}"
      end

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

    unless defined?(AnotherRenderSpecClass)
      class ::AnotherRenderSpecClass < RenderSpecClass
        def self._template_name_for(name, opts = {})
          opts[:format] ||= :html
          names = []
          names << "#{name}.#{ENV['RACK_ENV']}.#{opts[:format]}" if ENV['RACK_ENV']
          names << "#{name}.#{opts[:format]}"
          names
        end
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

  it "should provide me with a template from the class" do
    template = RenderSpecClass.template(:haml_template)
    template.should be_a_kind_of(Pancake::Mixins::Render::Template)
  end

  it "should allow me to set the format for a given template" do
    template = RenderSpecClass.template(:erb_template, :format => :json)
    template.should be_a_kind_of(Pancake::Mixins::Render::Template)
    template.name.should == "erb_template.json"
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
    @render.render(:context_template)
    $captures.first.should be_a_kind_of(Pancake::Mixins::Render::ViewContext)
  end

  it "should yield v when rendering" do
    mock_v = {}
    mock_v.should_receive(:in_the_block)
    @render.should_receive(:v).and_return(mock_v)
    @render.render(:haml_template) do |v|
      v.should be_a_kind_of(Hash)
      v.in_the_block
    end
  end

  it "should render the first avaibale template with the rack env set" do
    begin
      orig_env = ENV['RACK_ENV']
      ENV['RACK_ENV'] = 'foo_env'


      renderer = AnotherRenderSpecClass.new
      template = AnotherRenderSpecClass.template(:alternate)
      template.name.should == "alternate.foo_env.html"

      response = renderer.render(:alternate)
      response.should include("In alternate.foo_env.html")
    ensure
      ENV['RACK_ENV'] = orig_env
    end
  end

  it "should render the correct template with the rack env set" do
    begin
      orig_env = ENV['RACK_ENV']
      ENV['RACK_ENV'] = nil


      renderer = AnotherRenderSpecClass.new
      template = AnotherRenderSpecClass.template(:alternate)
      template.name.should == "alternate.html"

      response = renderer.render(:alternate)
      response.should include("In alternate.html")
    ensure
      ENV['RACK_ENV'] = orig_env
    end
  end
end
