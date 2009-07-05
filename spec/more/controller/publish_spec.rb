require File.dirname(__FILE__) + '/../../spec_helper'

describe "Pancake::Controller publish declaration" do
  before(:all) do
    class Test < Pancake::Controller
      
      publish
      def simple_publish; end
      
      publish :id => as_integer
      def integer_test; end
      
      publish :start => as_date
      def date_test; end
      
      publish :page => as_integer(12)
      def default_test; end
      
      publish :provides => [:xml, :json]
      def provides_test; end
      
      publish :only_provides => :xml
      def only_provides_test; end
    end
  end
  
  it "should publish an action" do
    Test.actions['simple_publish'].is_a?(Pancake::Controller::ActionOptions).should == true
  end
  
  it "should coerce a parameter into an integer" do
    params = Test.validate_and_coerce_params('integer_test', 'id' => "30")
    params['id'].should == 30
  end
  
  it "should coerce a parameter into a date" do
    date = Date.parse("2009/07/05")
    params = Test.validate_and_coerce_params('date_test', 'start' => "2009/07/05")
    params['start'].should == date
  end
  
  it "should allow parameters to be optional"
  
  it "should return a default value for a parameter" do
    params = Test.validate_and_coerce_params('default_test', {})
    params['page'].should == 12
  end
  
  it "should append formats to the list allowed for an action" do
    Test.actions['provides_test'].formats.should == [:html, :xml, :json]
  end
  
  it "should replace the list of formats allowed for an action" do
    Test.actions['only_provides_test'].formats.should == [:xml]
  end
end
