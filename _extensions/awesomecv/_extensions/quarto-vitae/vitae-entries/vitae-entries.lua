--- Document meta value
local doc_meta = pandoc.Meta{}

-- Helper: extract plain text from a cell
local function cell_text(cell)
	return pandoc.utils.stringify(cell)
end

-- Guess a pandoc input format from a file name or extension.
-- Returns a valid pandoc format string (e.g. "markdown", "latex", "docx").
-- For unknown extensions, falls back to "markdown".
local function guess_format_from_ext(path)
  if not path or path == "" then
    return "markdown"
  end

  -- grab last extension: "foo.bar.md" -> "md"
  local ext = path:match("%.([^%.]+)$")
  if not ext then
    return "markdown"
  end
  ext = ext:lower()

  -- main mapping: extensions -> pandoc input formats
  local map = {
    -- Markdown variants
    md      = "markdown",
    markdown= "markdown",
    rmd     = "markdown",
    qmd     = "markdown",
    txt     = "markdown",   -- often plain text / markdown

    -- Common lightweight markup
    rst     = "rst",
    rest    = "rst",
    org     = "org",
    typ     = "typst",        -- Typst: no pandoc input format yet

    -- TeX / LaTeX
    tex     = "latex",

    -- HTML / XML
    html    = "html",
    htm     = "html",
    xhtml   = "html",
    xml     = "html",

    -- JSON / native AST
    json    = "json",     -- pandoc JSON AST

    -- Word processing formats
    docx    = "docx",
    docm    = "docx",     -- macro-enabled docx, still docx for parsing
    odt     = "odt",
    rtf     = "rtf",

    -- Ebooks
    epub    = "epub",
    epub2   = "epub",
    epub3   = "epub",

    -- Misc
    ipynb   = "ipynb"
  }

  return map[ext] or "markdown"
end

local entry_templates = {
  detailed = "_extensions/awesomecv/detailed.html",
  simple = "_extensions/awesomecv/simple.html",
}

local function provided_templates(meta)
  -- TODO: Add provided templates to entry_templates

  -- TODO: match the current quarto output_format rather than 1st item
  -- local format = quarto.doc.output_format()  -- e.g. "awesomecv-html"
  
  -- quarto.log.output("meta:", Meta)

  -- local fmt_meta

  -- if meta.format then
  --   for k, v in pairs(meta.format) do
  --     -- pick any html-based extension
  --     if v and v.vitae ~= nil then
  --       fmt_meta = v
  --       break
  --     end
  --   end
  -- end


  -- quarto.log.output(fmt_meta)
  -- if fmt_meta.vitae then
  --   -- ...
	--   quarto.log.output("Success custom templates")
  -- end


  -- entry_templates = {
  --   detailed = "_extensions/awesomecv/detailed.html",
  -- }

  return entry_templates
end

local function use_template(file, data)
	local f = io.open(file, "r")
	if not f then
		error("Cannot open template " .. file)
	end
	local content = f:read("*a")
	f:close()
  local format = guess_format_from_ext(file)
  local template = pandoc.template.compile(content)
	local filled = pandoc.template.apply(template, data)
  local rendered = pandoc.layout.render(filled)
  return pandoc.read(rendered, format).blocks
end

local function vitae_entries(el)
	local output = {}
	for i, row in ipairs(el.bodies[1].body) do
		local cells = row.cells
		local context = {
			title = cell_text(cells[1]),
			organization = cell_text(cells[2]),
			location = cell_text(cells[1]),
			date = cell_text(cells[2]),
		}

		output[#output + 1] = context
	end
	local template_data = { rows = output }

  entry_templates(doc_meta)
  
  local template_file = entry_templates.detailed

  local cv_entries = use_template(template_file, template_data)

	return cv_entries
end


return {
  {
    Meta = provided_templates
  },
  {
    Table = vitae_entries
  }
}
