return function (value, inspect)
  return inspect(value, {
    process = function(item, path)
      if type(item) == "function" then
        return nil
      end

      if path[#path] == inspect.METATABLE then
        return nil
      end

      return item
    end,
    newline = " ",
    indent = ""
  })
end
