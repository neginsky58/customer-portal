
class Location < Array
 def add(text, linkto="")
  self.push({ :text => ERB::Util::h(text), :linkto => linkto })
 end
end
