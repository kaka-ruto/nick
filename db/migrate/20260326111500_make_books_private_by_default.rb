class MakeBooksPrivateByDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :books, :everyone_access, from: true, to: false
  end
end
