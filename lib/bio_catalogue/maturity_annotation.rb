module BioCatalogue
  module MaturityAnnotation

    def self.find_maturity link
      #document = `curl #{link}`
      if link =~ URI::regexp
        document = open(link, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
        if !document.nil?
          document = document.read
          document.gsub!("\n", "")
          match = /(Actionstoimprovetheservicedescription\">)+(.*?<\/div>)/.match(document)
          unless match.nil? or match.captures.nil?
            string = match.captures.last
            string.gsub!("</div>", "")
            string.strip!
            string = "#{link}<br/><hl/><h2>#{string}"
          end
          return string
        else return ''
        end
      else return ''
      end
    end


    def self.update_maturity_annotations
      maturity_attribute = AnnotationAttribute.where(:name => 'maturity_url')
      attr = maturity_attribute.first
      maturity_annotations = Annotation.where(:attribute_id => attr.id)
      count = 0
      maturity_annotations.each do |ann|
        desc = ann.value.text
        if desc.strip.start_with?('http://', 'https://')
          desc = desc.strip # remove leading and trailing whitespace
          split_desc = desc.split('<br/>')
          pulled_description = find_maturity split_desc[0]
          puts "DEBUG INFO====\n"
          puts "#{Digest::SHA1.hexdigest pulled_description}\n#{Digest::SHA1.hexdigest desc}"
          puts "\n\n#{pulled_description}\n#{desc}"
          unless pulled_description.eql?(desc)
            split_desc[1] = desc
            split_desc.join("<br/>")
            ann.update_attributes(:value => desc)
            if ann.save!
              count = count + 1
            end
          end
        end

      end
      puts "Updated #{count} BioVeL maturity annotations"
    end
  end
end