require 'active_record'

require 'ts_vectors/model'

class ActiveRecord::Base
  include ::TsVectors::Model
end