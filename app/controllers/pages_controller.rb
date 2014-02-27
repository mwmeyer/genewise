require 'net/http'

def fetch_hgnc_gene(gene_symbol)
    
  url = URI.parse('http://rest.genenames.org/fetch/symbol/%s' % gene_symbol)
  req = Net::HTTP::Get.new(url.path, {'Accept' => 'application/json'})
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  result = JSON.parse(res.body)

  if result['response']['numFound'] > 0
    
    return {
     symbol: result['response']['docs'][0]['symbol'],
     full_name: result['response']['docs'][0]['name'],
     date_identified: result['response']['docs'][0]['date_approved_reserved']
   }
     
  else
    return nil
  end

end

def fetch_fasta_file(gene_symbol)

  # search nucleotide database for gene symbol
  uri = URI.parse("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&term=#{gene_symbol}[Gene]+AND+Homo%20Sapiens[Organism]+AND+mRNA[Filter]+AND+RefSeq[Filter]&retmode=json")
  response = Net::HTTP.get_response(uri)
  result = JSON.parse(response.body)

  if result['esearchresult']['count'].to_i > 0

    # check first gene result for fasta file
    id = result['esearchresult']['idlist'][0]

    uri = URI.parse("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=#{id}&rettype=fasta")
    response = Net::HTTP.get_response(uri)

    if response.code == '200'
      return response.body
    else
      return nil
    end

  end

end

def fetch_publications(gene_symbol, retstart=0)

  uri = URI.parse("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=#{gene_symbol}&retmax=4&retstart=#{retstart}&retmode=json")
  response = Net::HTTP.get_response(uri)
  result = JSON.parse(response.body)

  if result['esearchresult']['count'].to_i > 0

    @publications = {count: result['esearchresult']['count'], pubs: []}

    for id in result['esearchresult']['idlist'] 
      uri = URI.parse("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=#{id}&retmode=json")
      response = Net::HTTP.get_response(uri)
      result = JSON.parse(response.body)

      pub = {
              title: result['result'][id]['title'],
              pubdate: result['result'][id]['pubdate'],
              authors: [],
            }

      for author in result['result'][id]['authors']
        pub[:authors] << author['name']
      end

      pub[:authors] = pub[:authors].join(", ")

      @publications[:pubs] << pub

    end 

    return @publications

  else 
    return nil
  end

end

class PagesController < ApplicationController
  def home
  end

  def search

    @gene = Gene.find_by symbol: params[:q]

    if @gene.nil?

      # gene isn't in our database, go check hgnc api
      hgnc_gene = fetch_hgnc_gene(params[:q])

      # hgnc didn't return a gene
      if hgnc_gene.nil?
        @no_results_found = true
        return
      end

      # new gene found, insert into database
      @gene = Gene.new
      @gene.symbol = hgnc_gene[:symbol]
      @gene.full_name = hgnc_gene[:full_name]
      @gene.date_identified = hgnc_gene[:date_identified]

      # fetch gene sequence data from a second api
      fasta_file = fetch_fasta_file(@gene.symbol)

      if !fasta_file.nil?
        @gene.fasta_file = fasta_file
      end

      @gene.save!

    end

    # fetch scientific publications from a 3rd api, these are not saved to database
    @publications = fetch_publications(@gene.symbol)

  end

  def fasta
    gene = Gene.find_by symbol: params[:symbol]
    send_data gene.fasta_file, :filename => '%s.fasta' % gene.symbol, :type => 'text/plain', :disposition => 'attachment'
  end

  def publications

    gene_symbol = params[:gene_symbol]
    retstart = params[:retstart]

    publications = fetch_publications(gene_symbol, retstart=retstart)

    render :json => { :publications => publications }
  end
end
