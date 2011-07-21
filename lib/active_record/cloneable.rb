module ActiveRecord::Cloneable
  # ------------------------------------------------------------------- included
  def self.included( base )
    base.extend( ClassMethods )
  end
  module ClassMethods
    def cloneable
      # HACK: check that this best way
      class_eval <<-EOV
      include ActiveRecord::Cloneable
      EOV
    end
  end
  # ---------------------------------------------------------------------- clone
  def clone_record( args = {} )
    puts "Cloning #{self.class.name}"
    args[:shared_parent_relations] ||= []
    args[:cloned_parents] ||= []
    args[:skipped_children] ||= []
    args[:attributes] ||={}
    cloned_record = self.class.new
    data = {}
    self.class.reflections.each do |k,v|
      data[v.macro] ||= []
      data[v.macro] << v
    end
    belongs_to_keys = ( data[:belongs_to] || [] ).map{ |x| x.primary_key_name }
    # assign the attributes, minus any assigned or any from a belongs_to relation
    self.class.content_columns.each do |column|
      if args[:attributes].has_key?( column.name.to_sym ) && !belongs_to_keys.include?( column.name )
        cloned_record.write_attribute( column.name, read_attribute( column.name ) )
      end
    end
    args[:attributes].each_pair do |k,v|
      cloned_record.write_attribute( k, v )
    end
    # Set the name or title field to be the existing value + (copy)
    ( args[:name_fields] || [:name,:title] ).each do |name_attr|
      if has_attribute?( name_attr ) && read_attribute( :name_attr )
        cloned_form.write_attribute( name_attr, read_attribute( name_attr ) + ' (copy)' )
        break if args[:name_fields].nil?
      end
    end
    ((data[:has_many] || []) + (data[:has_and_belongs_to_many]||[]) + (data[:has_one]||[]) ).each do |child_relation|
      next if child_relation.through_reflection
      kids = send( child_relation.name )
      next if kids.nil?
      kids.each do |child_record|
        next if args[:skipped_children].include?( child_record )
        child_args = { :cloned_parents => args[:cloned_parents] + [self], :attributes => {}}
        if child_relation.macro == :has_many ||child_relation.macro  == :has_one
          child_args[:attributes][child_relation.primary_key_name.to_sym] = nil
        end
        cloned_child_record = child_record.clone_record( child_args )
        cloned_record.send( child_relation.name ) << cloned_child_record
      end
    end
    ( data[:belongs_to] || []).each do |parent_relation|
      obj = send( parent_relation.name )
      next if obj.nil?
      if args[:shared_parent_relations].include?( parent_relation.name.to_sym )
        cloned_record.send( "#{parent_relation.name}=", obj )
      elsif !args[:cloned_parents].include?( obj )
        cloned_record.send( "#{parent_relation.name}=", obj.clone_record( :skipped_children => args[:skipped_children] + [self] ) )
      end
    end
    puts "Finished cloing #{self.class.name}"
    return cloned_record
  end
end
