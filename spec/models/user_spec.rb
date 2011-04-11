require 'spec_helper'

describe User do
  fixtures :users, :jobs, :roles
  describe 'a new user' do
    before(:each) do
      @user = User.new
      @user.valid?
    end
    it 'should want a first name' do
      @user.errors[:first_name].should include("is required for every employee")
    end
    it 'should want a last name' do
      @user.errors[:last_name].should include("is required for every employee")
    end
    it 'should want a job' do
      @user.errors[:job].should include("is required")
    end
    it 'should set the default role' do
      @user.errors[:role].should_not include("is required")
      @user.role.should == Role.default_role
    end
    describe 'after creation' do
      before(:each) do
        job = jobs(:opssupport)
        manager = users(:rcooper)
        attributes = {
          :first_name => 'John',
          :last_name => 'Doe',
          :email => 'jdoe@example.com',
          :job => job,
          :password => 'asdfasdf',
          :password_confirmation => 'asdfasdf',
          :manager => manager
        }
        @user.attributes = attributes
        @user.should be_valid
      end
      it 'should not allow blank role' do
        @user.save
        @user.role = nil
        @user.valid?
        @user.errors[:role].should include("is required")
      end
      it 'should not allow blank login' do
        @user.save
        @user.login = nil
        @user.valid?
        @user.errors[:login].should include("is required")
      end
      it 'should notify manager of activation' do
        @user.should_receive(:notify_manager).and_return(true)
        @user.activate!
      end
    end
  end
end

