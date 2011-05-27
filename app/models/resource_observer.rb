class ResourceObserver < ActiveRecord::Observer
  
  # TODO need to enable notifications when resource owners are add/removed
  
  # for some reason just don't feel like deleteing these...just in case
  # def before_validation(record)
    # ::ApplicationController::logger.info{"\n**** before_validation"}
    # ::ApplicationController::logger.info{"\n**** # permissions: #{record.permissions.size}"}
  # end
  
  # def after_validation(record)
    # ::ApplicationController::logger.info{"\n**** after_validation"}
    # ::ApplicationController::logger.info{"\n**** # permissions: #{record.permissions.size}"}
  # end
  
  # def before_save(record)
    # ::ApplicationController::logger.info{"\n**** before_save"}
    # ::ApplicationController::logger.info{"\n**** # permissions: #{record.permissions.size}"}
  # end
  
  # def after_save(record)
    # ::ApplicationController::logger.info{"\n**** after_save"}
    # ::ApplicationController::logger.info{"\n**** # permissions: #{record.permissions.size}"}
  # end
  
  # def after_commit(record)
    # ::ApplicationController::logger.info{"\n**** after_commit"}
    # ::ApplicationController::logger.info{"\n**** # permissions: #{record.permissions.size}"}
  # end
end