#! /usr/bin/env lua
--
-- _ticket.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local function fake_Ticket(...)
  local args = {...}
  if #args == 2 then
    return {
      schema=args[1],
      name_space=args[2],
    }
  elseif #args == 3 then
      local engine = args[1]
      local ks,ns= args[3]:match("^([%a_.]+)@?(.*)$")
      ns = ns and #ns>0 and ns or args[2]

    return {
      engine = args[1],
      schema = engine.schema,
      klass = ks,
      name_space = ns,
    }
  end
end

Ticket = LevelDb and Ticket or fake_Ticket
return Ticket

