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
          m = "#{column.name}=".to_sym
          if cloned_record.respond_to?( m )
            cloned_record.send( m, read_attribute( column.name ) )
          else
            cloned_record.write_attribute( column.name, read_attribute( column.name ) )
          end
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
      #cloned_record.save
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
          # We don't know what the parent calls this child.
          begin
            rec = obj.clone_record( :skipped_children => args[:skipped_children] + [self],
                :skipped_child_relations => find_applicable_clone_args( parent_relation.name, args[:skipped_child_relations] ),
                :skipped_parent_relations => find_applicable_clone_args( parent_relation.name, args[:skipped_parent_relations] ),
                :shared_parent_relations => find_applicable_clone_args( parent_relation.name, args[:shared_parent_relations] )
              )
          rescue NoMethodError
            raise "#{obj.class.name} objects do not know how to clone themselves; they should be marked as cloneable or skipped."
          end
          cloned_record.send( "#{parent_relation.name}=", rec )
        end
      end
    end
    # ----------------------------------------------- find_applicable_clone_args
    def find_applicable_clone_args( relation_name, args )
      relation_name = relation_name.to_sym
      return nil if args.nil?
      r_val = args.map do |x|
        if x.is_a?( Hash )
          x[relation_name]
        else
          nil
        end
      end
      r_val.flatten
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
      belongs_to_keys = ( data[:belongs_to] || [] ).map{ |x| x.association_primary_key }

      clone_belongs_to_relations( data[:belongs_to], cloned_record, args )
      clone_basic_details( cloned_record, belongs_to_keys, args )

      ((data[:has_many] || []) + (data[:has_and_belongs_to_many]||[])  ).each do |child_relation|
        next if child_relation.through_reflection
        next if !clone_child_relation?( child_relation.name, args[:skipped_child_relations] )
        kids = send( child_relation.name )
        next if kids.nil?
        kids.each do |child_record|
          next if args[:skipped_children].include?( child_record )
          cloned_child_record = kids.build
          child_args = { :cloned_parents => args[:cloned_parents] + [self], :attributes => {}, :object => cloned_child_record,
              :skipped_child_relations => find_applicable_clone_args( child_relation.name, args[:skipped_child_relations] ) }
          #if child_relation.macro == :has_many ||child_relation.macro  == :has_one
          #  child_args[:attributes][child_relation.primary_key_name.to_sym] = nil
          #end
          begin
            cloned_child_record = child_record.clone_record( child_args )
            cloned_record.send( child_relation.name ) << cloned_child_record
          rescue NoMethodError
            raise "#{child_record.class.name} objects do not know how to clone themselves; they should be marked as cloneable or skipped. (#{self.class.name} / #{child_relation.name}"
          end
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
        begin
          cloned_child_record = kid.clone_record( child_args )
          cloned_record.send( "#{child_relation.name}=",  cloned_child_record )
        rescue NoMethodError
          raise "#{kid.class.name} objects do not know how to clone themselves; they should be marked as cloneable or skipped. (#{self.class.name} / #{child_relation.name}"
        end
      end
      return cloned_record
    end
  end
end
