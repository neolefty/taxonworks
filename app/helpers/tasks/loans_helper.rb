module Tasks::LoansHelper
  def select_box

  end

  def new_taxon_determination(bio_object = nil)
    # we can add a biological_collection_object to this 'new' when we figure out which one
    @taxon_determination = TaxonDetermination.new
  end
end
