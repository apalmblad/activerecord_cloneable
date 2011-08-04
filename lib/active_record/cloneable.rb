module ActiveRecord::Cloneable
  # ------------------------------------------------------------------- included
  def self.included( base )
    base.extend( ClassMethods )
  end
  module ClassMethods
    # ---------------------------------------------------------------- cloneable
    def cloneable
      # HACK: check that this best way
      class_eval <<-EOV
      include ActiveRecord::Cloneable::InstanceMethods
      EOV
    end
  end
  module InstanceMethods
    # ------------------------------------------------------ clone_basic_details
    def clone_basic_details(cloned_record, belongs_to_keys, args )
      # assign the attributes, minus any assigned or any from a belongs_to relation
      self.class.content_columns.each do |column|
        if !args[:attributes].has_key?( column.name.to_sym ) && !belongs_to_keys.include?( column.name.to_sym )
          cloned_record.write_attribute( column.name, read_attribute( column.name ) )
        end
      end
      args[:attributes].each_pair do |k,v|
        cloned_record.send( "#{k}=", v )
      end
      # Set the name or title field to be the existing value + (copy)
      ( args[:name_fields] || [:name,:title] ).each do |name_attr|
        if has_attribute?( name_attr ) && read_attribute( :name_attr )
          cloned_form.write_attribute( name_attr, read_attribute( name_attr ) + ' (copy)' )
          break if args[:name_fields].nil?
        end
      end
      cloned_record.save!
    end
    # ----------------------------------------------- clone_bleongs_to_relations
    def clone_belongs_to_relations( relations, cloned_record, args )
      return if relations.nil?
      relations.each do |parent_relation|
        obj = send( parent_relation.name )
        next if obj.nil?
        if args[:shared_parent_relations].include?( parent_relation.name.to_sym )
          cloned_record.send( "#{parent_relation.name}=", obj )
        elsif !args[:cloned_parents].include?( obj )
          cloned_record.send( "#{parent_relation.name}=", obj.clone_record( :skipped_children => args[:skipped_children] + [self] ) )
        end
      end
    end
    # ---------------------------------------------------- clone_child_relation?
    def clone_child_relation?( relation_name, skipped_child_relations )
      relation_name = relation_name.to_sym
      skipped_child_relations.each do |relation|
        unless relation.is_a?( Hash )
          return false if relation == relation_name
        end
      end
      return true
    end
    # ---------------------------------------------------------------------- clone
    def clone_record( args = {} )
      args[:shared_parent_relations] ||= []
      args[:skipped_child_relations] ||= []
      args[:cloned_parents] ||= []
      args[:skipped_children] ||= []
      args[:attributes] ||={}
      cloned_record = args[:object] || self.class.new
      data = {}
      self.class.reflections.each do |k,v|
        data[v.macro] ||= []
        data[v.macro] << v
      end
      belongs_to_keys = ( data[:belongs_to] || [] ).map{ |x| x.primary_key_name.to_sym }

      clone_belongs_to_relations( data[:belongs_to], cloned_record, args )
      clone_basic_details( cloned_record, belongs_to_keys, args )

      ((data[:has_many] || []) + (data[:has_and_belongs_to_many]||[])  ).each do |child_relation|
        next if child_relation.through_reflection
        next if !clone_child_relation?( child_relation.name, args[:skipped_child_relations] )
        kids = send( child_relation.name )
        next if kids.nil?
        records = kids.find( :all )
        records.each do |child_record|
          next if args[:skipped_children].include?( child_record )
          cloned_child_record = kids.build
          child_args = { :cloned_parents => args[:cloned_parents] + [self], :attributes => {}, :object => cloned_child_record,
              :skipped_child_relations => args[:skipped_child_relations].find_all{ |x| x.is_a?( Hash ) && x[child_relation.name.to_sym]  }.map{ |x| x.values }.flatten }
          #if child_relation.macro == :has_many ||child_relation.macro  == :has_one
          #  child_args[:attributes][child_relation.primary_key_name.to_sym] = nil
          #end
          cloned_child_record = child_record.clone_record( child_args )
          cloned_record.send( child_relation.name ) << cloned_child_record
        end
      end
      ( data[:has_one] || []).each do |child_relation|
        next if child_relation.through_reflection
        next if !clone_child_relation?( child_relation.name, args[:skipped_child_relations] )
        kid = send( child_relation.name )
        next if kid.nil?
        next if args[:skipped_children].include?( kid )
        cloned_child_record = kid.build
        child_args = { :cloned_parents => args[:cloned_parents] + [self],
            :attributes => {}, :object => cloned_child_record,
            :skipped_child_relations => args[:skipped_child_relations].find_all{ |x| x.is_a?( Hash ) && x[child_relation.name.to_sym]  }.map{ |x| x.values }.flatten }
        cloned_child_record = child_record.clone_record( child_args )
        cloned_record.send( "#{child_relation.name}=",  cloned_child_record )
      end
      return cloned_record
    end
  end
end
