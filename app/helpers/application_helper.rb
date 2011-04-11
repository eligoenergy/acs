module ApplicationHelper
  
  def table_info_row(items, options = {})
    if items.respond_to? :total_pages
      render :partial => 'shared/pagination_row', :locals => { :items => items, :colspan => options[:colspan] }
    else
      render :partial => 'shared/no_pagination_row', :locals => { :items => items, :colspan => options[:colspan], :item_type => options[:item_type] }
    end
  end
end
