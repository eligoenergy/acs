class Admin::MailerTemplatesController < ApplicationController
  before_filter :require_admin_or_hr
  
  def index
    @mailer_templates = MailerTemplate.paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
  end
  
  def edit
    @mailer_template = MailerTemplate.find(params[:id])
  end
  
  def edit_description
    @mailer_template = MailerTemplate.find(params[:id])
  end
  
  def update
    @mailer_template = MailerTemplate.find(params[:id])
    respond_to do |format|
      if @mailer_template.update_attributes(params[:mailer_template])
        format.html { redirect_to(edit_admin_mailer_template_path(@mailer_template), :notice => 'Email template was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mailer_template.errors, :status => :unprocessable_entity }
      end
    end
  end
end
