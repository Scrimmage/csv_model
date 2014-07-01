using CSVModel::Extensions

module CSVModel
  class ObjectWithStatusSnapshot < SimpleDelegator
    include RecordStatus

    def assign_attributes(attributes)
      __getobj__.try(:assign_attributes, attributes)
    end

    def errors
      if __getobj__.nil?
        ["Record could not be created or updated"]
      else
        value = __getobj__.errors
        value.try(:full_error_messages) || value
      end
    end

    def mark_as_duplicate
      @is_duplicate = true
    end

    def save(options = {})
      capture_state(options[:dry_run])
      @was_saved = was_editable? && was_valid? && (is_dry_run? || __getobj__.save(options))
    end

    def status
      return ERROR_ON_READ if __getobj__.nil?
      return DUPLICATE if is_dry_run? && is_duplicate?
      return status_for_new_record if was_new?
      return status_for_existing_record if was_existing?
      UNKNOWN
    end

    def valid?
      __getobj__.try(:valid?)
    end

    private

    def capture_state(dry_run)
      @is_dry_run = dry_run == true
      if !__getobj__.nil?
        @was_changed = changed?
        @was_deleted = marked_for_destruction?
        @was_editable = __getobj__.respond_to?(:editable?) ? __getobj__.editable? : true
        @was_new = new_record?
        @was_valid = valid?
      end
    end

    def is_duplicate?
      @is_duplicate
    end

    def is_dry_run?
      @is_dry_run
    end

    def status_for_existing_record
      return DELETE if was_deleted?
      return NOT_CHANGED if !was_changed?
      return UPDATE if was_valid? && was_saved?
      ERROR_ON_UPDATE # if (!was_editable? || !was_valid? || !was_saved?)
    end


    def status_for_new_record
      return ERROR_ON_DELETE if was_deleted?
      return ERROR_ON_CREATE if was_not_valid?
      CREATE # if valid?
    end

    def was_changed?
      @was_changed
    end

    def was_deleted?
      @was_deleted
    end

    def was_editable?
      @was_editable
    end

    def was_existing?
      !was_new?
    end

    def was_new?
      @was_new
    end

    def was_saved?
      @was_saved
    end

    def was_not_valid?
      !was_valid?
    end

    def was_valid?
      @was_valid
    end

  end
end
