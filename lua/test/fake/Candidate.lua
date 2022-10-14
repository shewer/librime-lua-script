#! /usr/bin/env lua
--
-- Candidate.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
require 'tools/debugtool'
local class =require 'tools/class'

local Candidate = class({
  __name = 'Cand',
  _initialize=function(self,type,s,e,text,comment)
    self.type= type
    self.start=s
    self.text = text
    self.comment = comment
    return self
  end

} )

return Candidate


