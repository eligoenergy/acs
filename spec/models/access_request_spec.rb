require 'spec_helper'

describe AccessRequest do
  # fixtures :access_requests, :resources, :departments, :jobs, :locations, :permission_requests, :permission_types, :permissions, :resource_groups, :roles, :users
  describe "a new request" do
    before(:each) do
      @access_request = AccessRequest.new
      @access_request.valid?
    end
    it "should be pending" do
      @access_request.current_state.should == 'pending'
    end
    it "should not require a permission request if pending" do
      @access_request.errors[:base].should_not include("An Access Request requires at least one permission request")
    end
    it "should want a resource" do
      @access_request.errors[:base].should include("An Access Request needs to be for a resource")
    end
    it "should want a user" do
      @access_request.errors[:base].should include("An Access Request must be created for an employee")
    end
    it "should want a creator" do
      @access_request.errors[:base].should include("An Access Request must have a creator")
    end
    it "should want to grant or deny" do
      @access_request.errors[:base].should include("An Access Request must grant or deny access")
    end
  end
end