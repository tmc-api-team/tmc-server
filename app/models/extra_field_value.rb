# See UserFieldValue
module ExtraFieldValue
  extend ActiveSupport::Concern

  included do
    validates :field_name, :uniqueness => {:scope => :user_id}
  end

  def field
    @field ||= ExtraField.by_kind(field_kind).find {|f| f.name == self.field_name }
  end

  def field_kind
    @field_kind ||= self.class.name.underscore.gsub(/_field_value$/, '').to_sym
  end

  def set_from_form(new_value)
    if self.field.should_save?
      self.value =
        case field_kind
        when :boolean
          new_value.to_bool
        else
          new_value.to_s
        end
    end
  end

end