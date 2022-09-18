#! /usr/bin/env lua
--
-- _candidate.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local class = require 'tools/class'
if TEST and not Candidate then 
  Candidate = require 'test/fake/Candidate'
end
-- warp ShadowCandidate
if ShadowCandidate then 
  return 
end
-- not work  not a  an<Candidate> userdata
ShadowCandidate= class({
  _initialize=function(self,cand,type,text,comment)
    self._cand = cand
    self.type=type
    self.text=text
    self.comment=comment
    self.start=start
    self._end=_end
    return self
  end,

})
local hook_tab={}

-- for old versino  
local function fake_SCandidate( cand, _type, text, comment)
  _type = _type or cand.type
  text = text or cand.text
  comment = comment or cand.comment
  hook_tab[cand]= Candidate(_type, cand.start, cand._end, text, comment)
  return hook_tab[cand]
end

ShadowCandidate = LevelDb and ShadowCandidate or fake_SCandidate
return ShadowCandidate
