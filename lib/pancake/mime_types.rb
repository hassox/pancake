require 'set'
require 'rack/accept_media_types'
module Pancake
  module MimeTypes
    # A collection of all the mime types that pancake knows about
    #
    # @returns [Array<Pancake::MimeTypes::Type>] an array of
    # Pancake::MimeTypes::Type objects that pancake knows about.  To
    # add a new type to the collection, simply create a new
    # Pancake::MimeTypes::Type
    #
    # @see Pancake::MimeTypes::Type
    # @api public
    # @author Daniel Neighman
    def self.types
      @types || reset! && @types
    end
    
    # Finds a Pancake::MimeTypes::Type object by the provided
    # extension
    #
    # @param ext [String,Symbol] - The extension to look for
    # @return [Pancake::MimeTypes::Type, nil] - The corresponding mime
    # type object or nil if there were none found that match the
    # provided extension
    #
    # @example
    #   Pancake::MimeTypes.type_by_extension("html") # => A
    #   Pancake::MimeTypes::Type object for the .html extension
    #
    # @see Pancake::MimeTypes::Type
    # @api public
    # @author Daniel Neighman
    def self.type_by_extension(ext)
      ext = ext.to_s
      types.detect{|t| t.extension == ext}
    end
    
    # Pancake manages mime types by grouping them together.
    # 
    # @return [Set<Pancake::MimeTypes::Type>] - A enumerable of Type
    # objects associated with this group
    #
    # @see Pancake::MimeTypes.group
    # @api public
    # @author Daniel Neighman
    def self.groups
      @groups || reset! && @groups
    end
    
    # Pancake::MimeTypes are managed by grouping them together.
    # Each group may consist of many mime types by extension
    # By Accessing a group that doesn't yet exist, the group is
    # created and initialized with the matching type wwith extension
    # A group may have many mime type / accept types associated with
    # it
    #
    # @param name [String,Symbol] - The name of the group
    #
    # @example
    #   Pancake::MimeTypes.group(:html)
    #
    # @return [Enumerable<Pancake::MimeTypes::Type>] - returns all
    # mime types in the specified group.  If the group does not exist,
    # or has not been accessed, the group will be created on the fly
    # with the first mime type that matches the group name
    #
    # @see Pancake::MimeTypes.group_as
    # @api public
    # @author Daniel Neighman
    def self.group(name)
      groups[name.to_s]
    end
    
    # Creates a group of mime types.  Any group of mimes can be
    # arbitrarily grouped under the specified name.  The group is
    # initilized with the mime type whose extension matches the name,
    # and any further extensions have their mime types added to the
    # group
    #
    # @param name [String,Symbol] - the name of the group to
    # create/append
    # @param exts [List of String,Symbol] - a list of extensions to
    # associate with this mime type
    #
    # @see Pancake::MimeTypes.group
    # @api public
    # @author Daniel Neighman
    def self.group_as(name, *exts)
      exts.each do |ext|
        group(name) << type_by_extension(ext) unless group(name).include?(type_by_extension(ext))
      end
      group(name)
    end
    
    # Resets the Pancake::MimeType cache and re-creates the
    # Pancake::MimeTypes default types and groups
    # Good for use in specs
    # @api private
    def self.reset!
      @types = []
      @negotiated_accept_types = nil
      @groups = Hash.new do |h,k|
        k = k.to_s
        h[k] = []
        t = Pancake::MimeTypes.type_by_extension(k)
        h[k] << t unless t.nil?
        h[k]
      end
      reset_mime_types!
      reset_mime_groups!
    end

    # Used in specs to reset the mime types back to their
    # corresponding originals in Rack::Mime::MIME_TYPES
    # @api private
    def self.reset_mime_types!
      # Setup the mime types based on the rack mime types
      Rack::Mime::MIME_TYPES.each do |ext, type|
        ext =~ /\.(.*)$/
        e = $1
        t = type_by_extension(ext)
        if t
          t.type_strings << type 
       else
          t = Type.new(e, type) 
        end
      end
    end
    
    # Used in specs to reset the default mime groups of
    # pancake::MimeTypes
    # @api private
    def self.reset_mime_groups!
      # html
      group_as(:html, "html", "htm", "xhtml")
      group_as(:text, "text", "txt")
      type_by_extension("xml").type_strings << "text/xml"

      group_as(:svg, "svgz")
    end
    
    # Negotiates the type and group that the accept_type string
    # matches
    # @param type [String] the accept_type header string from the
    # request
    # @param provided [list of String,Symbol] - A list of strings /
    # symbols of the included groups to use to try and match this
    # accept type header.
    #
    # @example
    #   accept_type = "text/xml,text/html"
    #   result = Pancake::MimeTypes.negotiate_accept_type(accept_type, :html,
    #  :text)
    #  result # => [:html, <#Pancake::MimeTypes::Type for html>]
    #
    # @return [Array] An array with the group name, and mime type
    # @api public
    # @author Daniel Neighman
    def self.negotiate_accept_type(type, *provided)
      accepted_types = Rack::AcceptMediaTypes.new(type)
      provided = provided.flatten
      key = [accepted_types, provided]
      return negotiated_accept_types[key] if negotiated_accept_types[key]
      
      accepted_type = nil
      
      if accepted_types.include?("*/*")
        name = provided.first
        accepted_type = group(name).first
        negotiated_accept_types[key] = [name, accepted_type.type_strings.first, accepted_type]
        return negotiated_accept_types[key]
      end
      
      # Check to see if any accepted types match
      accepted_types.each do |at|
        provided.flatten.each do |name|
          accepted_type = match_content_type(at, name)
          if accepted_type
            at = accepted_type.type_strings.first if at == "*/*"
            if accepted_types.join.size > 4096
              # Don't save the key if it's larger than 4 k.
              # This could hit a dos attack if it's repeatedly hit
              # with anything large
              negotiated_accept_types[key] = [name, at, accepted_type]
            end
            return [name, at, accepted_type]
          end
        end
      end
      nil
    end
    
    # Negotiates the content type based on the extension and the
    # provided groups to see if there is a match.
    #
    # @param ext [String] The extension to negotiate
    # @param provided [Symbol] A list of symbols each of which is the
    # name of a mime group
    #
    # @return [Symbol, String, Pancake::MimeTypes::Type] The first
    # parameter returned is the group name that matched.  The second,
    # is the Content-Type to respond to the client with, the third,
    # the raw pancake mime type
    #
    # @see Pancake::MimeTypes.group
    # @see Pancake::MimeTypes::Type
    # @api public
    def self.negotiate_by_extension(ext, *provided)
      provided = provided.flatten
      key = [ext, provided]
      return negotiated_accept_types[key] if negotiated_accept_types[key]

      result = nil
      provided.each do |name|
        group(name).each do |type|
          if type.extension == ext
            result = [name, type.type_strings.first, type]
            negotiated_accept_types[key] = result
            return result
          end
        end
      end
      result
    end # self.negotiate_by_extension
    

    # A basic type for mime types
    # Each type can have an extension and many type strings that
    # correspond to the mime type that would be specified in a request
    # When a Pancake::MimeTypes::Type is created, it is added to the
    # Pancake::MimeTypes.types collection
    # @api public
    class Type
      attr_reader   :type_strings, :extension

      def initialize(extension, *type_strings)
        @extension = extension
        @type_strings = []
        type_strings.flatten.each do |ts|
          @type_strings << ts
        end
        MimeTypes.types << self
      end
    end
    
    private
    # Checks to see if a group matches an accept type string
    # @api private
    def self.match_content_type(accept_type, key)
      group(key).detect do |t|
        t.type_strings.include?(accept_type) || accept_type == "*/*"
      end
    end
    
    # Provides a cache for already negotiated types
    # @api private
    def self.negotiated_accept_types
      @negotiated_accept_types ||= {}
    end
        
  end # MimeTypes
end # Pancake


