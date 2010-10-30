class RunProgram < ActiveRecord::Base
  belongs_to :run
  belongs_to :program
end
