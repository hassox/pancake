require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short::Controller do
  
  before do
    class ::ShortFoo < Pancake::Stacks::Short; end
  end
  
  after do 
    clear_constants "ShortFoo"
  end

  it "should have a Controller" do 
    Pancake::Stacks::Short.constants.map(&:to_s).should include("Controller")
  end
  

end