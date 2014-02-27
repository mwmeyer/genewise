require 'bio'

class Gene < ActiveRecord::Base
    def sequence
        f = Bio::FastaFormat.new(self.fasta_file)
        return f.seq
    end
end
