module ApplicationHelper
  
  def table_info_row(items, options = {})
    if items.respond_to? :total_pages
      render :partial => 'shared/pagination_row', :locals => { :items => items, :colspan => options[:colspan] }
    else
      render :partial => 'shared/no_pagination_row', :locals => { :items => items, :colspan => options[:colspan], :item_type => options[:item_type] }
    end
  end
  
  # this is just a copy paste of button_to but creates a button instead of input
  def real_button_to(name, options = {}, html_options = {})
    html_options = html_options.stringify_keys
    convert_boolean_attributes!(html_options, %w( disabled ))

    method_tag = ''
    if (method = html_options.delete('method')) && %w{put delete}.include?(method.to_s)
      method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
    end

    form_method = method.to_s == 'get' ? 'get' : 'post'

    remote = html_options.delete('remote')

    request_token_tag = ''
    if form_method == 'post' && protect_against_forgery?
      request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
    end

    url = options.is_a?(String) ? options : self.url_for(options)
    name ||= url

    html_options = convert_options_to_data_attributes(options, html_options)

    html_options.merge!("type" => "submit")

    ("<form method=\"#{form_method}\" action=\"#{html_escape(url)}\" #{"data-remote=\"true\"" if remote} class=\"button_to\"><div>" +
      method_tag + content_tag("button", name, html_options) + request_token_tag + "</div></form>").html_safe
  end
end
