--[[
Description:
    FileName:pbocTLV.lua
Notes:
  针对银联标准的TLV进行解包、组包
]]
module(..., package.seeall)
local bitTYPE = require("common.bit32")

local function to_bin(str)
	local s = str:gsub("..", function(x) return string.char(tonumber(x, 16)) end)
	return s
end

local function to_hex(str)
	return str:gsub(".", function(c) return string.format("%02X", c:byte(1)) end)
end

local M = {}
function M:new()
    local o = {}
    setmetatable(o,self);
    self.__index = self;
    self.value   = {}
    return o;
end

-- 解包，将tag 和 value BCD展开之后存在TABLE中
function M:parse(icF55)
	self.value   = {}
	local tag,lenss,val;
	local pos = 0;
	local len = 0;
	local bit = bitTYPE:new();

	--print("len:"..icF55:len());
	while (true) do
		--print("pos:"..pos);
		if pos>=icF55:len() then
			break;
		end

		tag = icF55:sub(pos+1, pos+1);
		if bit:_and(string.byte(tag:sub(1,1)),0X0F)==0X0F then
			tag = icF55:sub(pos+1, pos+2);
			pos = pos + 2;
		else
			pos = pos + 1;
		end
		--print("tag:"..to_hex(tag))

		lenss = icF55:sub(pos+1, pos+1);
		if bit:_and(string.byte(lenss:sub(1,1)),0X80)==0X80 then
			local len_tmp = bit:_and(string.byte(lenss:sub(1,1)),0X7F);
			--print("len_tmp:"..len_tmp)
			pos = pos + 1;
			len = 0;
			if len_tmp~=0 then
				local BaseNum = 256;
				for i=1, len_tmp do
					--print("00:"..i)
					--print("11:"..string.byte(icF55:sub(pos+i, pos+i)));
					len = len + (BaseNum^(i-1))*string.byte(icF55:sub(pos+i, pos+i));
				end
			end
			pos = pos + len_tmp;
		else
			pos = pos + 1;
			len = string.byte(lenss:sub(1,1));
		end
		if len~=0 then
			val = icF55:sub(pos+1,pos+len);
			pos = pos + len;

			tag = to_hex(tag);
			val = to_hex(val);
			self.value[string.upper(tag)] = string.upper(val);
		else
			tag = to_hex(tag);
			val = "";
			self.value[string.upper(tag)] = string.upper(val);
		end
	end
	return self.value;
end

-- 按BCD展开的TAG查询
function M:get(key)
	assert(key)
	return self.value[key]
end

--[[
local ss = "9F26086239817E082FC3829F2701809F101307140103A0A004010A010000000000C14CD33B9F37049A61A2159F36020115950508000460009A031507209C01009F02060000000000015F2A02015682027C009F1A0201569F03060000000000009F3303E0E1C89F34030203009F3501229F1E0833503630373030358408A0000003330101019F090200209F4104000000179F42820101AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBC"
ss = to_bin(ss)

local mm = M:new()
mm:parse(ss)

for key,val in pairs(mm.value) do
	print(key..":"..val)
end
]]
return M;
