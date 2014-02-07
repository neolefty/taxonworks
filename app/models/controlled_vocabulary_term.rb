class ControlledVocabularyTerm < ActiveRecord::Base
  include Housekeeping
  include Shared::AlternateValues

  validates_presence_of :name, :definition, :type
  validates_length_of :definition, minimum: 4

end
