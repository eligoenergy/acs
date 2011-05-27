class RequestMailer < ActionMailer::Base
  default :from => App.email[:from]

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.requests.request_receipt.subject
  #
  def request_receipt(request)
    @request = request
    @user = @request.user
    @url = request_url(@request)
    
    mail :to => @request.user.email
  end

  def request_complete(request)
    @request = request
    @user = @request.user
    @url = request_url(@request)
    
    mail :to => @request.user.email
  end
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.requests.notify_manager_of_pending_request.subject
  #
  def notify_manager(request)
    @greeting = "Hi"

    mail :to => "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.requests.notify_help_desk.subject
  #
  def notify_resource_owner(request, user)
    @request = request
    @user = user
    @url = request_url(@request)
    
    mail :to => @user.email
  end
  
  def notify_help_desk(request, user)
    @request = request
    @user = user
    @url = request_url(@request)
    
    mail :to => @user.email
  end
  
  def notify_help_desk_of_new_user(request, user)
    @request = request
    @user = user
    @url = request_url(@request)
    
    mail :to => @user.email
  end
  
  def notify_help_desk_of_terminated_user(request, user)
    @request = request
    @user = user
    @url = request_url(@request)
    
    mail :to => @user.email
  end
  
end
