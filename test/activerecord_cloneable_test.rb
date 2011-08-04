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
    has_one :bread
  end
  class NonCloneableThing < ActiveRecord::Base
    belongs_to :apple
  end
  class Bread < ActiveRecord::Base
    cloneable
    belongs_to :banana
  end
  test "Basic test" do
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
  def test_with_non_cloneable_things
    Apple.has_many( :non_cloneable_things )
    original = Banana.new
    original.save
    a = original.apples.create
    a.non_cloneable_things.create
    original.save
    clone = original.clone_record( :skipped_child_relations => [{ :apples => :non_cloneable_things}] )
    assert( clone.apples.any? )
  end
  def test_with_have_one
    b = Bread.new
    b.banana = Banana.new
    b.save!
    new_bread = b.clone_record( :skipped_parent_relations => [ { :bread => :banana }] )
    new_bread.save!
    assert( new_bread.banana )
    assert_equal( new_bread, new_bread.banana.bread )
  end
end
