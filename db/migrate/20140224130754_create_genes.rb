class CreateGenes < ActiveRecord::Migration
  def change
    create_table :genes do |t|
      t.string :symbol
      t.string :full_name
      t.datetime :date_identified

      t.timestamps
    end
  end
end
