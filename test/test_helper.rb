require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_record'
require 'activerecord_cloneable'
ActiveRecord::Base.send( :include, ActiveRecord::Cloneable )
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", 
                                       :database => ':memory:' )
class DoSetup < ActiveRecord::Migration
  def self.up
    create_table :breads do |t|
      t.column :banana_id, :integer
    end
    create_table :non_cloneable_things do |t|
      t.column :apple_id,:integer
    end
    create_table :apples do |t|
      t.column :banana_id, :integer
    end
    create_table :bananas do |t|
    end
  end

 def self.down
   drop_table :bananas
   drop_table :non_cloneale_things
   drop_table :apples
 end
end
begin
  DoSetup.up
rescue ActiveRecord::StatementInvalid => e
  DoSetup.down
  raise e
end
