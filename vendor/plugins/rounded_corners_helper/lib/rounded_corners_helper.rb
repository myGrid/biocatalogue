module RoundedCornersHelper
  def rounded(background, color, width, &block)
		output = self
	  output.concat "<div class=\"rcontainer\" style=\"width:#{width};\">"
	  output.concat "<div class=\"rtop\">"
	  output.concat "<div class=\"r1\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r2\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r3\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r4\" style=\"background:#{background};\"></div>"
	  output.concat "</div>"
	  output.concat "<div class=\"rcontain\" style=\"background:#{background};color:#{color};\">"
		block.call
		output.concat "</div>"
	  output.concat "<div class=\"rbottom\">"
	  output.concat "<div class=\"r4\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r3\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r2\" style=\"background:#{background};\"></div>"
	  output.concat "<div class=\"r1\" style=\"background:#{background};\"></div>"
	  output.concat "</div>"
	  output.concat "</div>"
  end
end