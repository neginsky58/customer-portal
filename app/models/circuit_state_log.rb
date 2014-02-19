class CircuitStateLog < ActiveRecord::Base
  belongs_to :circuit_state
  belongs_to :user
end

