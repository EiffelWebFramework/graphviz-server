note
	description: "Summary description for {GRAPHVIZ_FORMATS}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Graphviz - Output Formats", "protocol=URI", "src=http://www.graphviz.org/doc/info/output.html", "tag=page, specification"

class
	GRAPHVIZ_FORMATS
feature -- available formats

	bmp : STRING = "bmp"
		--Windows Bitmap Format

	canon : STRING = "canon"

	dot : STRING = "dot"

	xdot : STRING = "xdot"
		-- dot

	eps : STRING = "eps"
		--Encapsulated PostScript

	fig : STRING = "fig"
		--FIG
	gd : STRING = "gd"

	gd2 : STRING = "gd2"
		--GD/GD2 formats

	gif : STRING = "gif"
		--GIF

	gtk : STRING = "gtk"
		--GTK canvas

	ico : STRING = "ico"
		--Icon Image File Format

	imap : STRING = "imap"

	cmapx : STRING = "cmapx"
		--Server-side and client-side imagemaps

	imap_np : STRING = "imap_np"

	cmapx_np : STRING = "cmapx_np"
		--Server-side and client-side imagemaps

	jpg : STRING = "jpg"

	jpeg : STRING = "jpeg"

	jpe  : STRING = "jpe"

	pdf  : STRING = "pdf"
		--Portable Document Format (PDF)
	plain : STRING = "plain"

	plain_ext : STRING = "plain-ext"
		--Simple text format

	png : STRING = "png"
		--Portable Network Graphics format

	ps : STRING = "ps"
		--PostScript

	ps2 : STRING = "ps2"
		--PostScript for PDF

	svg : STRING = "svg"

	svgz : STRING = "svgz"
		--Scalable Vector Graphics
	tif : STRING = "tif"

	tiff :STRING = "tiff"
		--TIFF (Tag Image File Format)
	vml  :STRING = "vml"

	vmlz :STRING ="vmlz"
		--Vector Markup Language (VML)

	vrml :STRING = "vrml"
		--VRML
	wbmp :STRING = "wbmp"
		--Wireless BitMap format
	webp :STRING = "webp"
		--Image format for the Web
	xlib :STRING = "xlib"
		--Xlib canvas

feature -- deprecated
	cmap : STRING = "cmap"
		--	Client-side imagemap (deprecated)

	ismap : STRING = "ismap"
		--erver-side imagemap (deprecated)	
end
