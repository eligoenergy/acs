class TransferController < ApplicationController
  def new
    @user = User.find(params[:id])
    @managers = User.managers.alphabetical_login.all
    @employment_types = EmploymentType.alphabetical.all
  end

  def create
    @user = User.find(params[:id])
    @managers = User.managers.alphabetical_login.all
    @employment_types = EmploymentType.alphabetical.all
  
    @old_job = @user.job
    @manager = User.find(params[:user][:manager_id])
    unless @manager == @user.manager
      @user.manager = @manager
      UserMailer.notify_manager_of_user_transfer(@user, @manager, current_user).deliver
    end
    @new_job = Job.find(params[:user][:job_id])
    unless @old_job == @new_job
      @user.transfer_employee(@new_job, current_user)
    end
    if @user.save
      flash[:notice] = "Employee transfer completed."
      redirect_to user_path(@user)
    else
      render 'new'
    end
  end

end

