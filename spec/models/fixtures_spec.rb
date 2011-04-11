require 'spec_helper'

describe 'Valid fixtures' do
  fixtures :users, :jobs, :departments, :locations, :permissions, :resource_groups, :roles, :permission_types, :access_requests, :resources, :permission_requests
  describe User do
    it 'should have 5 users' do
      User.count.should == 5
    end
    it 'should only have 1 root' do
      User.where({:manager_id => nil}).all.should have_exactly(1).items
    end
    [
      ['Timothy', 'Ho', 'timothyho', 'timothyho@example.com', 'president', 'public', true, true, 4],
      ['Roland', 'Cooper', 'rcooper', 'rcooper@example.com', 'opssupport', 'admin', false, true, 1],
      ['Dan', 'Engle', 'dengle', 'dengle@example.com', 'opssupport', 'admin', false, false, 0],
      ['Marc', 'Groulx', 'mgroulx', 'mgroulx@example.com', 'product_mgmt_director', 'public', false, true, 0],
      ['Nadine', 'Ott', 'nott', 'nott@example.com', 'recruiting_coordinator', 'hr', false, true, 0]
    ].each do |input|
      f = FixtureValidator.new(
        :first_name => input[0],
        :last_name => input[1],
        :login => input[2],
        :email => input[3],
        :job => input[4],
        :role => input[5],
        :root => input[6],
        :manager => input[7],
        :subordinates => input[8]
      )
      describe "#{f.first_name} #{f.last_name}" do
        before(:all) do
          @user = User.find_by_login f.login
        end
        describe 'basic info' do
          it "should have first_name #{f.first_name}" do
            @user.first_name.should == f.first_name
          end
          it "should have last_name #{f.last_name}" do
            @user.last_name.should == f.last_name
          end
          it "should have login #{f.login}" do
            @user.login.should == f.login
          end
          it "should have email #{f.email}" do
            @user.email.should == f.email
          end
        end
        it "should have #{f.job} as their job" do
          job = jobs(f.job.to_sym)
          @user.job.should == job
        end
        it "should have #{f.role} role" do
          role = roles(f.role.to_sym)
          @user.role.should == role
        end
        it "should #{'not ' unless f.manager}have manager flag" do
          if f.manager
            @user.manager_flag.should be_true
          else
            @user.manager_flag.should be_false
          end
        end
        it "should #{'not' unless f.root} be root in nested_set" do
          if f.root
            @user.parent_id.should be_blank
          else
            @user.parent_id.should_not be_blank
          end
        end
        it "should have #{f.subordinates} subordinates" do
          @user.descendants.should have_exactly(f.subordinates).items
        end
      end
    end
  end

  describe Location do
    it 'should have 1 location' do
      Location.all.should have_exactly(1).items
    end
    it 'should be Chicago, IL' do
      Location.first.name.should == "Chicago, Il"
    end
  end

  describe Department do
    it 'should have 4 departments' do
      Department.all.should have_exactly(4).items
    end
    [
      ['IT Administration', 'chicago', 1],
      ['Product Management', 'chicago', 1],
      ['Executive Admin', 'chicago', 2],
      ['Human Resources', 'chicago', 1]
    ].each do |input|
      f = FixtureValidator.new(
        :name => input[0],
        :location => input[1],
        :jobs => input[2]
      )
      describe "#{f.name}" do
        before(:all) do
          @department = Department.find_by_name f.name
        end

        it "should be named #{f.name}" do
          @department.name.should == f.name
        end

        it "should have #{f.jobs} jobs" do
          @department.should have_exactly(f.jobs).jobs
        end
      end
    end
  end

  describe Job do
    it 'should have 5 jobs' do
      Job.all.should have_exactly(5).items
    end
    [
      ['Ops Support Engineer CNU', 'it_admin',
        ['wiki', 'cnu_portal_admin'],
        ['rcooper', 'dengle']
      ],
      ['Director of Product Management', 'product_management',
        ['wiki', 'cnu_portal_executive'],
        ['mgroulx']
      ],
      ['President Internet Services', 'executive_admin',
        ['wiki'],
        ['timothyho']
      ],
      ['Recruiting Coordinator', 'human_resources',
        ['wiki'],
        ['nott']
      ],
      ['Administrative Asst Cashnet', 'executive_admin',
        ['wiki'],
        []
      ]
    ].each do |input|
      f = FixtureValidator.new(
        :name => input[0],
        :department => input[1],
        :permissions => input[2],
        :users => input[3]
      )
      describe f.name do
        before(:all) do
          @job = Job.find_by_name f.name
        end
        it "should be named #{f.name}" do
          @job.name.should == f.name
        end
        it "should have #{f.permissions.size} permissions" do
          @job.should have_exactly(f.permissions.size).permissions
        end
        it "should have #{f.users.size} employees" do
          @job.should have_exactly(f.users.size).users
        end
      end
    end
  end
  describe AccessRequest do
    it 'should have 2 valid access requests' do
      AccessRequest.all.should have_exactly(2).items
      AccessRequest.all.each {|ar| ar.should be_valid }
    end
  end
end

