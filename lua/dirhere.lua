-- Note this is copy pasted from TamaMcGlinn/nvim-lsp-gpr-selector
-- commit 21ae246096b66a5fd0a7e7ea25c13905823df554
-- lines 1 - 44
local function split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local function get_files_in_dir(file_pattern, dir, recursive)
  local wildcard = recursive and "/**/" or "/"
  -- after implementing, I decided recursive is too dangerous to include
  -- if you open a random file and do :GPRSelect you potentially search
  -- all files on the whole system
  return split(vim.fn.glob(dir..wildcard..file_pattern))
end

local function parent_of(dir)
  if dir == "/" then
    return nil
  end
  local parent = dir:match("(.*)/")
  if parent == "" then
    return "/"
  else
    return parent
  end
end

local function find_files_upwards(file_match, dir, recursive)
  local project_files = {}
  while #project_files == 0 do
    project_files = get_files_in_dir(file_match, dir, recursive)
    if #project_files == 0 then
      dir = parent_of(dir)
      if dir == nil then
        return {}
      end
    end
  end
  return project_files
end
-- end copy paste

local function get_project_root()
  local file_globs = {"*.gpr", "Makefile", "WORKSPACE"}
  local current_file = vim.api.nvim_buf_get_name(0)
  local dir = parent_of(current_file)
  for idx,val in ipairs(file_globs) do
    local matched_files = find_files_upwards(val, current_file, false)
    if #matched_files ~= 0 then
      return parent_of(matched_files[1])
    end
  end
end

return {
  get_project_root = get_project_root
}
