class Index < ActiveRecord::Base
  self.table_name = "schema_migrations"
  default_scope { order("version desc") }
  # Substring size when splitting to fit in a VARCHAR column
  SHOE_SIZE = 200

  def self.find(id)
    rows = where("version like '=#{id}=%' or version like '-#{id}-%'")
    if rows.any?
      rows.map{|r| r.attributes["version"]}.sort_by{|r| r.sub('-\d-','').to_i}.map{|v| v.sub(/^-\d+-\d+-/,'')}.reverse.join
    end
  end

  # Split the version string into subsstrings and insert them with an indexed prefix.
  def self.shoehorn(version)
    new_id = highest_id + 1
    version.chars.each_slice(SHOE_SIZE).map(&:join).each_with_index do |v,index|
      Index.connection.execute("insert into schema_migrations (version) values ('-#{new_id}-#{index}-#{v}')")
    end
    new_id
  end

  # Find the id of the latest inserted string, so we can manually set the primary key.
  # Will cause race conditions and corrupt entries when concurrently inserting.
  def self.highest_id
    records = all.where("version like '-%'")
    if records.any?
      records.map do |rec|
        rec.attributes["version"].
        match(/^-(\d+)-/)[1]
      end.
      compact.sort.last.to_i
    else
      0
    end
  end
end
