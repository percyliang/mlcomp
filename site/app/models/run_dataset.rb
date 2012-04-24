class RunDataset < ActiveRecord::Base
  belongs_to :run
  belongs_to :dataset
end
