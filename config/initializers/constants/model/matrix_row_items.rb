# Be sure to restart your server when you modify this file.

Rails.application.config.after_initialize do 
  MATRIX_ROW_ITEM_TYPES = ObservationMatrixRowItem.descendants.inject({}){|hsh,a| hsh.merge(a.name => a.human_name) }.freeze
end
