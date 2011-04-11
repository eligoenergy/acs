class CsvImportController < ApplicationController
  layout 'access_control'
  require 'csv'

  def csv_import
    @file = params[:csv][:file]
    @type = params[:csv][:filetype]
    @columns = CONFIG['csvtypes'][@type]
    @results = []
    @import_results = []
    CSV::Reader.parse(params[:csv][:file]).each { |line|
      next if line.compact.empty?
      line_dupe = line.clone
      line.push(current_user.preferred_name)
      @results.push(line_dupe.push(validate_line(line_dupe,@type)))
#      logger.error "Type: #{@type} Line: #{line.join(',')}"
        if line_dupe.last == true
          @import_results << `#{RAILS_ROOT}/script/runner script/csv_importer.rb #{@type} '#{line.join(',')}'`
        else
          @import_results << "Line format invalid"
        end
#      logger.error "#{@import_results}"
    }

 #       flash[:notice] = "Upload Successful"
        render :controller => 'csv_import', :action => "csv_summary", :layout => 'access_control'

  end

  def csv_summary
    @page_title = "CSV Import Summary"
  end

  def csv
    render :file => 'csv_import/csv_import.html.erb'
  end

private
  def validate_line(line,type)
    cols = CONFIG['csvtypes'][type].size
    return true if line.size == cols
    return false
  end

  # Currently unused
  def validate_all_lines(file,type)
    cols = CONFIG['csvtypes'][type].size
    return true if line.size == cols
    return false
  end

end

