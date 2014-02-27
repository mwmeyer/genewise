class AddFastaFileToGenes < ActiveRecord::Migration
  def change
    add_column :genes, :fasta_file, :text
  end
end
