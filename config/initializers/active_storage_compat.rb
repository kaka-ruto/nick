ActiveSupport.on_load(:active_record) do
  include ActiveStorage::Attached::Model unless respond_to?(:has_one_attached)

  if defined?(ActiveStorage::Reflection::ActiveRecordExtensions)
    include ActiveStorage::Reflection::ActiveRecordExtensions
    ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
  end
end
