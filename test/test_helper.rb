require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_record'
require 'active_record/cloneable'
ActiveRecord::Base.send( :include, ActiveRecord::Cloneable )
ActiveRecord::Base.establish_connection(:adapter  => 'mysql',
        :database => 'cloneable_test',
        :username => 'root' )
class DoSetup < ActiveRecord::Migration
  def self.up
    create_table :apples do |t|
      t.column :banana_id, :integer
    end
    create_table :bananas do |t|
    end
  end

 def self.down
   drop_table :bananas
   drop_table :apples
 end
end
begin
  DoSetup.up
rescue ActiveRecord::StatementInvalid => e
end
