require 'test_helper'

class ActiveRecordCloneableTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  class Apple < ActiveRecord::Base
    cloneable
    belongs_to :banana
    validates_presence_of :banana
    validates_associated :banana
  end
  class Banana < ActiveRecord::Base
    cloneable
    has_many :apples
  end
  test "the truth" do
    original = Banana.new
    original.save
    a = original.apples.build
    apple =original.apples.new
    original.save!
    original.reload
    assert( original.apples.any? )
    clone = original.clone_record
    clone.save!
    assert( clone.apples.any? )
  end
end
