json.extract! source, :id, :serial_id, :address, :annote, :author, 
  :booktitle, :chapter, :crossref, :edition, :editor, 
  :howpublished, :institution, :journal, :key, :month, :note, 
  :number, :organization, :pages, :publisher, :school, :series, 
  :title, :type, :volume, :doi, :abstract, :copyright, :language, 
  :stated_year, :verbatim, :cached, :cached_author_string, 
  :bibtex_type, :created_by_id, :updated_by_id, :cached_nomenclature_date, 
  :day, :year, :isbn, :issn, :verbatim_contents, :verbatim_keywords, 
  :language_id, :translator, :year_suffix, :url, :created_at, :updated_at

json.source_in_project source_in_project?(source)

json.partial! '/shared/data/all/metadata', object: source, klass: 'Source'

json.documents do |d|
  d.array! source.documents, partial: '/documents/attributes', as: :document
end

