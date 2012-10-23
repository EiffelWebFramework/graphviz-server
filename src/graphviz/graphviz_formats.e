note
	description: "Summary description for {GRAPHVIZ_FORMATS}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Graphviz - Output Formats", "protocol=URI", "src=http://www.graphviz.org/doc/info/output.html", "tag=page, specification"

class
	GRAPHVIZ_FORMATS

feature -- Validator

	is_supported (a_type: READABLE_STRING_8) : BOOLEAN
		-- is `type' a valid format.
		do
			Result := supported_formats.has (a_type.as_lower)
		end

feature -- Access

	set_supported_formats (lst: LIST [READABLE_STRING_8])
		local
			arr: ARRAY [STRING_8]
			i: INTEGER
		do
			create arr.make_filled (lst.first, 1, lst.count)
			i := arr.lower
			i := 1
			across
				lst as c
			loop
				arr.force (c.item, i)
				i := i + 1
			end
			arr.compare_objects
			supported_formats.copy (arr)
		end

	supported_formats: ARRAY [STRING_8]
		-- List of valid Graphviz format types
		once
			Result := <<
				"bmp", --Windows Bitmap Format
				"canon",
				"cmap", --	Client-side imagemap (deprecated)
				"cmapx", --Server-side and client-side imagemaps
				"cmapx_np", --Server-side and client-side imagemaps
				"dot",
				"emf",
				"emfplus",
				"eps", --Encapsulated PostScript
				"fig", --FIG
				"gd",
				"gd2", --GD/GD2 formats
				"gif", --GIF
				"gtk", --GTK canvas
				"gv",
				"ico", --Icon Image File Format
				"imap",
				"imap_np",
				"ismap", --erver-side imagemap (deprecated)
				"jpe",
				"jpeg",
				"jpg",
				"metafile",
				"pdf", --Portable Document Format (PDF)
				"plain",
				"plain-ext", --Simple text format
				"png", --Portable Network Graphics format
				"ps", --PostScript
				"ps2", --PostScript for PDF
				"svg",
				"svgz", --Scalable Vector Graphics
				"tif",
				"tiff", --TIFF (Tag Image File Format)
				"tk",
				"vml",
				"vmlz", --Vector Markup Language (VML)
				"wbmp", --Wireless BitMap format
				"webp", --Image format for the Web
				"vrml", --VRML
				"wbmp",
				"xdot", -- dot
				"xlib" --Xlib canvas
				>>
			Result.compare_objects
		end


end
