class UserMailer < ActionMailer::Base
  default :from => App.email[:from]

  def activation_email(user)
    @user = user
    @url = "http://#{SITE_URL}/account/activate/#{user.perishable_token}"
    mail(:to => user.email,
         :subject => 'Welcome, please activate your account')
  end

  def password_reset_email(user)
    @user = user
    @url = "http://#{SITE_URL}/account/reset_password/#{user.perishable_token}"
    mail(:to => user.email, :subject => 'Password reset')
  end

  def account_suspended_email(user)
    @user = user
    @url = "http://#{SITE_URL}"
    mail(:to => @user.email, :subject => 'Your account has been suspended')
  end

  def account_unsuspended_email(user)
    @user = user
    @url = "http://#{SITE_URL}"
    mail(:to => @user.email, :subject => 'Your account has been unsuspended')
  end

  def notify_hr_of_user_creation(user, hr_user)
    @user = user
    @hr_user = hr_user
    @url = user_path(@user)
    mail(:to => @hr_user.email, :subject => 'A new employee requires HR confirmation')
  end

  def notify_hr_of_user_termination_by_manager(user, hr_user)   
  	  @user = user
  	  @hr_user = hr_user
      @url = user_path(@user)
      mail(:to => @hr_user.email, :subject => 'A terminated employee requires HR confirmation')
  end

  def notify_manager_of_user_transfer(user, manager, submitter)
    @user = user
    @manager = manager
    @submitter = submitter
    mail(:to => @manager.email, :subject => "ATTENTION: Employee #{@user.full_name} is now yours")
  end

end

