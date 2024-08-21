math.randomseed(os.time())

function randomString(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

return {
  s("t", f(function(args, snip)
    local t = table.concat(snip.env.TM_SELECTED_TEXT, "")
    return "t`" .. t:sub(2, -2) .. "`"
  end, {})),

  s("cl", {
    t("console.log(\""),
    f(function()
      return randomString(4)
    end, {}),
    t(":\", "),
    i(1),
    t(");"),
  })
}
