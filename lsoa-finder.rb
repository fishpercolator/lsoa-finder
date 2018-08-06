require 'nokogiri'
require 'geokit'

class LSOA
  attr_reader :name, :geometry

  def initialize(name, geometry)
    @name = name
    @geometry = geometry
  end

  def contains?(lat, lng)
    point = Geokit::LatLng.new(lat, lng)
    geometry.contains? point
  end
end

class LSOAFinder
  attr_reader :lsoas

  def initialize(file)
    @lsoas = []
    kml = Nokogiri::XML.parse(open file)
    kml.css('Placemark').each do |pm|
      name = pm.css('SimpleData[name="lsoa11nmw"]').first.text
      points = pm.css('Polygon coordinates').first.text.split(' ').map do |lnglat|
        lng, lat = lnglat.split(',')
        Geokit::LatLng.new(lat, lng)
      end
      geometry = Geokit::Polygon.new(points)
      @lsoas << LSOA.new(name, geometry)
    end
  end

  def which(lat, lng)
    lsoas.find {|lsoa| lsoa.contains? lat, lng}
  end

  # Get your array of hashes with CSV.read('file.csv', headers: true, header_converters: :symbol)
  def add_lsoa_column_to(array_of_hashes)
    array_of_hashes.each do |h|
      puts h[:id]
      h[:lsoa] = which(h[:lat], h[:lng])&.name
    end
  end
end
