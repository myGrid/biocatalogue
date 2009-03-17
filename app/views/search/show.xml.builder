xml.instruct!(:xml)
xml.tag!("search-results") {
  @results.each { |type, res|
    type = type.underscore.dasherize
    xml.tag!(type.pluralize) {
      res.each { |item|
        xml << item.to_xml(:skip_instruct => true)
      }
    }
  }
}