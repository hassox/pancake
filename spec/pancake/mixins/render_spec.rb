require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Mixins::Render do
  before do
    class ::RenderSpecClass
      include Pancake::Mixins::Render
      extend  Pancake::Paths
      
      def roots
        []
      end
      
      
      def string
        render :text => "A String"
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
end