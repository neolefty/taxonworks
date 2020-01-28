require 'zip'

module Export

  # TODO: Explore https://github.com/frictionlessdata/datapackage-rb to ingest frictionless data,
  # then each module will provide a correspond method to each field
  # write tests to check for coverage (missing methods)
  # 
  # http://api.col.plus/datapackage
  # https://github.com/frictionlessdata/datapackage-rb
  # https://github.com/frictionlessdata/tableschema-rb
  #
  #
  # * Update all files formats to use tabs 
  #
  # Exports to the Catalog of Life in the new "coldp" format.
  module Coldp

    FILETYPES = %w{Description Name Synonym VernacularName}.freeze

    # @return [Scope]
    #   should return the full set of Otus (= Taxa in CoLDP) that are to
    #   be sent.
    # TODO: include options for validity, sets of tags, etc. 
    # At present otus are a mix of valid and invalid
    def self.otus(otu_id)
      o = ::Otu.find(otu_id)
      return ::Otu.none if o.taxon_name_id.nil?
      a = o.taxon_name.self_and_descendants
      ::Otu.joins(:taxon_name).where(taxon_name: a) 
    end

    def self.export(otu_id)
      otus = otus(otu_id)
      ref_csv = CSV.new('temp_ref_csv', col_sep: "\t")

      ref_csv << %w{ID citation	author year source details doi}

      # TODO: This will likely have to change, it is renamed on serving the file.
      zip_file_path = "/tmp/_#{SecureRandom.hex(8)}_coldp.zip"

      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
        # Synonym doesn't have source
        # Name uses different params
        (FILETYPES - ['Name']).each do |ft| 
          m = "Export::Coldp::Files::#{ft}".safe_constantize
          zipfile.get_output_stream("#{ft}.csv") { |f| f.write m.generate(otus, ref_csv) }
        end 

        zipfile.get_output_stream('Name.csv') { |f| f.write Export::Coldp::Files::Name.generate( Otu.find(otu_id), ref_csv) }
        zipfile.get_output_stream('Taxon.csv') { |f| f.write Export::Coldp::Files::Taxon.generate( otus, otu_id, ref_csv) }

        ref_csv.rewind
        zipfile.get_output_stream('References.csv') { |f| f.write ref_csv.string }
        ref_csv.close
      end
      
      zip_file_path
    end 

    def self.download(otu, request = nil)
      file_path = ::Export::Coldp.export(otu.id)
      name = "coldp_otu_id_#{otu.id}_#{DateTime.now}.zip"

      ::Download.create!(
        name: "ColDP Download for #{otu.otu_name} on #{Time.now}.",
        description: 'A zip file containing CoLDP formatted data.',
        filename: name,
        source_file_path: file_path,
        request: request,
        expires: 2.days.from_now
      )
    end

    def self.download_async(otu, request = nil)
      download = ::Download.create!(
        name: "ColDP Download for #{otu.otu_name} on #{Time.now}.",
        description: 'A zip file containing CoLDP formatted data.',
        filename: "coldp_otu_id_#{otu.id}_#{DateTime.now}.zip",
        request: request,
        expires: 2.days.from_now
      )
      
      ColdpCreateDownloadJob.perform_later(otu, download)

      download
    end

    # TODO - perhaps a utilities file --

    # @return [Boolean]
    def self.original_field(taxon_name)
      (taxon_name.type == 'Protonym') && taxon_name.is_original_name?
    end

    # TaxonWorks does not keep a seperate ID for ICZN names 
    #   that differ from their original combination.  Ultimately
    #   if it moves to use a Combination::Original method then
    #   we can use those IDs. The present rendering is a hack.
    def self.current_taxon_name_id(taxon_name)
      taxon_name.id.to_s + '/current'
    end

  end
end
