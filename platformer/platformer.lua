-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

t=0
x=96
y=24

function TIC()

	if btn(0) then y=y-1 end
	if btn(1) then y=y+1 end
	if btn(2) then x=x-1 end
	if btn(3) then x=x+1 end

	cls(9)
	spr(352+t%60//10*2,x,y,1,3,0,0,2,2)
	print("LET'S SWIM!",84,84,12)
	t=t+1
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:1111111111111100111110441111044411110440111104401111044411110344
-- 001:1111111100011111444011114444011144040111440401114444011144430111
-- 002:1111110011111044111104441111044011110440111104441111034411111033
-- 003:0001111144401111444401114404011144040111444401114443011133301111
-- 004:1111111111111100111110441111044411110440111104401111044411110344
-- 005:1111111100011111444011114444011144040111440401114444011144430111
-- 006:1111111111111100111110441111044411110444111104001111044411110344
-- 007:1111111100011111444011114444011144440111440001114444011144430111
-- 008:11111000111104441110444411104ccc11104c0c11104ccc1100344010a90330
-- 009:0011111144011111444011114cc011114c0011114cc011110430011103099011
-- 010:11111100111100ca1110ccca110accca10aaccca10aaacca0caaacca0ccaacca
-- 011:00111111ac001111accc0111accca011acccaa01accaaa01accaaac0accaacc0
-- 012:1111111111111111111111111111111111111111111111111111111111111111
-- 013:1111111111111111111111111111111111111111111111111111111111111111
-- 014:1111111111111111111111111111111111111111111111111111111111111111
-- 015:1111111111111111111111111111111111111111111111111111111111111111
-- 016:1111103311110aaa1110aa9a1110cc9a1110ccff11110f001110440111100001
-- 017:33301111aaa01111aaa90111aaad0111fffd011100f011111033011110000111
-- 018:11110aaa1110aa9a1110cc9a1110ccff11110f0011110f011110440111100001
-- 019:aaa01111aaa90111aaad0111fffd011100f0111110f011111033011110000111
-- 020:111100331110a9aa1110cc9a1110cc9a11110fff11110f001110440111100001
-- 021:33301111aaa90111aaad0111aaad0111fff0111100f011111033011110000111
-- 022:1111103311110aaa1110aa9a1110cc9a1110ccff11110f001110440111100001
-- 023:33301111aaa01111aaa90111aaad0111fffd011100f011111033011110000111
-- 024:10aaccaa1109ccaa1000ffff1044f00011034011111001111111111111111111
-- 025:aacc9011aacc0111fff0001100f4401110430111110011111111111111111111
-- 026:0cca90000dd00011000110110011101110111011110111011101110111101111
-- 027:0009acc011000dd0110110001101110011011101101110111011101111110111
-- 028:1111111111111111111111111111111111111111111111111111111111111111
-- 029:1111111111111111111111111111111111111111111111111111111111111111
-- 030:1111111111111111111111111111111111111111111111111111111111111111
-- 031:1111111111111111111111111111111111111111111111111111111111111111
-- 032:1111111111111100111110441111044411110444111104441111044411110344
-- 033:1111111100011111444011114444011104400111044001114444011144430111
-- 034:1111110011111044111104441111044411110444111104441111034411111033
-- 035:00011111444011114444011104400111044001114444011144430111333cc011
-- 036:1111111111111100111110441111044411110444111104441111044411110344
-- 037:1111111100011111444011114444011104400111044001114444011144430111
-- 038:1111111111111100111110441111044411110444111104441111044411110344
-- 039:1111111100011111444011114444011104400111044001114444011144430111
-- 040:1111110011111044111104441111044411110444111104441111034411110033
-- 041:000111114440111144440111044001110440011144440111444300113330cc01
-- 042:1111111111111100111110441111044411110444111104441111044411110344
-- 043:1111111100011111444011114444011104400111044001114444011144430111
-- 044:1111111111111111111111111111111111111111111111111111111111111111
-- 045:1111111111111111111111111111111111111111111111111111111111111111
-- 046:1111111111111111111111111111111111111111111111111111111111111111
-- 047:1111111111111111111111111111111111111111111111111111111111111111
-- 048:1111003311109aaa1110aacc111099cc11110fff111110f01111104411111000
-- 049:33301111aaa00111aaadd011aaadd011fff00111033011110000111101111111
-- 050:11110aaa111109aa1111109a111000ff11103ff0111030011110011111111111
-- 051:aaacc011aaa90111aa901111ffff0001000f4401110430111110011111111111
-- 052:1111103311110aaa111109aa111110aa111110ff111110331111100011111111
-- 053:33301111aaa01111aacc0111a9cc0111fff0111100f011110044011110000111
-- 054:1111003311109aaa1110aacc111099cc11110fff111110041111110011111111
-- 055:33301111aaa00111aaadd011aaadd011fff001114f0011110330111100001111
-- 056:1110a9aa1110cc9a1110ccaa111100ff1111110f111111041111111011111111
-- 057:aaa9cc01aaa99011aaa00111fff0111144011111301111110111111111111111
-- 058:111100331110aaaa11109cca11110cca111110ff1111110f1111110411111100
-- 059:33300011aaa9cc01aaa9cc01aaa00011fff01111ff0011114001111100111111
-- 060:1111111111111111111111111111111111111111111111111111111111111111
-- 061:1111111111111111111111111111111111111111111111111111111111111111
-- 062:1111111111111111111111111111111111111111111111111111111111111111
-- 063:1111111111111111111111111111111111111111111111111111111111111111
-- 064:11111100111110441111044411110444111104441100044410cc034410cc9a33
-- 065:00011111444011110440011104400111444401114444001144430d013330dd01
-- 066:1111110011111044111104441111044411110444111104441111034411110033
-- 067:0001111144401111444401114444011104400111044001114443011133300111
-- 068:1111111111111111111111001111104411110444111104441111044411110440
-- 069:1111111111111111000111114440111144440111444401114444011104400111
-- 070:1111110011111044111104441111044411110444111104441111034411110033
-- 071:00011111444011114444011104400111044001114444011144430111333dd011
-- 072:1111111111111111111111111111111111111111111111111111111111111111
-- 073:1111111111111111111111111111111111111111111111111111111111111111
-- 074:1111111111111100111110441111044411110404001004040c00c04410c0c044
-- 075:1111111100011111444011114444011144040111440401114444011144430111
-- 076:1111111111111111111111111111111111111111111111111111111111111111
-- 077:1111111111111111111111111111111111111111111111111111111111111111
-- 078:1111111111111111111111111111111111111111111111111111111111111111
-- 079:1111111111111111111111111111111111111111111111111111111111111111
-- 080:1109aaaa111099aa111109aa11000fff1103ff00110300111100111111111111
-- 081:aaa99011aaa90111aaff0001ffff440100043011111001111111111111111111
-- 082:1110aacc11109acc1111099a111110ff1111110f111111041111111011111111
-- 083:aaadd011aaadd011aaa00111fff0111144001111300111110111111111111111
-- 084:11110344111100331110acca11109cca1111099a111110ff1111104411111000
-- 085:4443011133301111aaad0111aaad0111aaa01111fff011114030111100001111
-- 086:1110aaaa110aa9aa1109ccaa1110ccff111100ff111111031111111011111111
-- 087:aaadd011aaa90d00aaa00040ffffff4030000000301111110011111111111111
-- 088:1111111111111111111111111111111111111111111111111111111111111111
-- 089:1111111111111111111111111111111111111111111111111111111111111111
-- 090:110dc03310ccc0aa10ccc0aa110009aa11110fff11110f001110440111100001
-- 091:33301111aaaa0111aaa9a011aaacc011fffcc01100f001111044011110000111
-- 092:1111111111111111111111111111111111111111111111111111111111111111
-- 093:1111111111111111111111111111111111111111111111111111111111111111
-- 094:1111111111111111111111111111111111111111111111111111111111111111
-- 095:1111111111111111111111111111111111111111111111111111111111111111
-- 096:111111111111111111111111111111111111111010001100103300d0110ff0d0
-- 097:1111111111111111100000110444440144444440444044004440440044444440
-- 098:11111111111111111111111111111110111111100011111003000000103fffaa
-- 099:1111111110000011044444014444444044404400444044004444444034444430
-- 100:111111111111111111111111111111101111111011111110111100001000ffaa
-- 101:1111111110000011044444014444444044404400444044004444444034444430
-- 102:111111111111111111111111111111111111111010001000103300c0110ff0cd
-- 103:1111111111111111100000110444440144444440444044004440440044444440
-- 104:11111111111111111111111111111110111111100011111003000000103fffaa
-- 105:1111111110000011044444014444444044404400444044004444444034ccc430
-- 106:111111111111111111111111111111101111111011111110111100001000ffaa
-- 107:1111111110000011044444014444444044404400444044004444444034444430
-- 108:1111111111111111111111111111111111111111111111111111111111111111
-- 109:1111111111111111111111111111111111111111111111111111111111111111
-- 110:1111111111111111111111111111111111111111111111111111111111111111
-- 111:1111111111111111111111111111111111111111111111111111111111111111
-- 112:1110ffaa11110faa11110faa1000ffaa104f0000040011110011111111111111
-- 113:3444443093333301aaaa0011a9aa0111009cc011110dc0111110c01111110011
-- 114:11000faa11000faa104fffaa040000000011110c111111001111111111111111
-- 115:93333301aaaaa011a9aa0111dc901111cc011111001111111111111111111111
-- 116:103ffdca104fccca1000ff991111000011111111111111111111111111111111
-- 117:93333301aa9aa01199a001110001111111111111111111111111111111111111
-- 118:1110ffcc11110f9911110fa91000ffaa104f0000040011110011111111111111
-- 119:34444430933333019aaaa001aaa00dd0000110d0111111001111111111111111
-- 120:11000faa11000faa104fffaa0400000000111111111111111111111111111111
-- 121:9acd3301aaa9a011aa900111000111110d011111100111111111111111111111
-- 122:103fffaa104fffaa1000ffaa1111000011111111111111111111111111111111
-- 123:93333300aaaaccc0a999cd010000001111111111111111111111111111111111
-- 124:1111111111111111111111111111111111111111111111111111111111111111
-- 125:1111111111111111111111111111111111111111111111111111111111111111
-- 126:1111111111111111111111111111111111111111111111111111111111111111
-- 127:1111111111111111111111111111111111111111111111111111111111111111
-- 128:1111111111110000111044441104444411044404110444041104444411034444
-- 129:1111111101111111401111114401111140011111400111114401111143011111
-- 130:1111111111111100111110441111044411110444111104441111044411110344
-- 131:1111111100011111444011114444011104400111044001114444011144430111
-- 132:1111111111111100111110441111044411110444111104441111044411110344
-- 133:1111111100011111444011114444011140440111404401114444011144430111
-- 134:1111111111111111111111111111111111111111111111111111111111111111
-- 135:1111111111111111111111111111111111111111111111111111111111111111
-- 136:1111111111111111111111111111111111111111111111111111111111111111
-- 137:1111111111111111111111111111111111111111111111111111111111111111
-- 138:1111111111111111111111111111111111111111111111111111111111111111
-- 139:1111111111111111111111111111111111111111111111111111111111111111
-- 140:1111111111111111111111111111111111111111111111111111111111111111
-- 141:1111111111111111111111111111111111111111111111111111111111111111
-- 142:1111111111111111111111111111111111111111111111111111111111111111
-- 143:1111111111111111111111111111111111111111111111111111111111111111
-- 144:11003333109aaaaa10aaccaa1099ccaa110fffff110ff0001104401111000011
-- 145:30111111a0011111add01111add01111f0011111ff0111110330111100001111
-- 146:111100331110aaaa1110acca11109cca11110fff1110ff001104401111000011
-- 147:33300000aaaaacc0aaa99dc0aa900000fff011110ff011110330111100001111
-- 148:1111003311109aaa11109aaa11109aaa11110fff1110ff001104401111000011
-- 149:33300000aaaaacc0aaa99dc0aa900000fff011110ff011110330111100001111
-- 150:1111111111111111111111111111111111111111111111111111111111111111
-- 151:1111111111111111111111111111111111111111111111111111111111111111
-- 152:1111111111111111111111111111111111111111111111111111111111111111
-- 153:1111111111111111111111111111111111111111111111111111111111111111
-- 154:1111111111111111111111111111111111111111111111111111111111111111
-- 155:1111111111111111111111111111111111111111111111111111111111111111
-- 156:1111111111111111111111111111111111111111111111111111111111111111
-- 157:1111111111111111111111111111111111111111111111111111111111111111
-- 158:1111111111111111111111111111111111111111111111111111111111111111
-- 159:1111111111111111111111111111111111111111111111111111111111111111
-- 160:1111111111111111111111111111111111111111111111111111111111111111
-- 161:1111111111111111111111111111111111111111111111111111111111111111
-- 162:1111111111111111111111111111111111111111111111111111111111111111
-- 163:1111111111111111111111111111111111111111111111111111111111111111
-- 164:1111111111111111111111111111111111111111111111111111111111111111
-- 165:1111111111111111111111111111111111111111111111111111111111111111
-- 166:1111111111111111111111111111111111111111111111111111111111111111
-- 167:1111111111111111111111111111111111111111111111111111111111111111
-- 168:1111111111111111111111111111111111111111111111111111111111111111
-- 169:1111111111111111111111111111111111111111111111111111111111111111
-- 170:1111111111111111111111111111111111111111111111111111111111111111
-- 171:1111111111111111111111111111111111111111111111111111111111111111
-- 172:1111111111111111111111111111111111111111111111111111111111111111
-- 173:1111111111111111111111111111111111111111111111111111111111111111
-- 174:1111111111111111111111111111111111111111111111111111111111111111
-- 175:1111111111111111111111111111111111111111111111111111111111111111
-- 176:1111111111111111111111111111111111111111111111111111111111111111
-- 177:1111111111111111111111111111111111111111111111111111111111111111
-- 178:1111111111111111111111111111111111111111111111111111111111111111
-- 179:1111111111111111111111111111111111111111111111111111111111111111
-- 180:1111111111111111111111111111111111111111111111111111111111111111
-- 181:1111111111111111111111111111111111111111111111111111111111111111
-- 182:1111111111111111111111111111111111111111111111111111111111111111
-- 183:1111111111111111111111111111111111111111111111111111111111111111
-- 184:1111111111111111111111111111111111111111111111111111111111111111
-- 185:1111111111111111111111111111111111111111111111111111111111111111
-- 186:1111111111111111111111111111111111111111111111111111111111111111
-- 187:1111111111111111111111111111111111111111111111111111111111111111
-- 188:1111111111111111111111111111111111111111111111111111111111111111
-- 189:1111111111111111111111111111111111111111111111111111111111111111
-- 190:1111111111111111111111111111111111111111111111111111111111111111
-- 191:1111111111111111111111111111111111111111111111111111111111111111
-- 192:1111111111111111111111111111111111111111111111111111111111111111
-- 193:1111111111111111111111111111111111111111111111111111111111111111
-- 194:1111111111111111111111111111111111111111111111111111111111111111
-- 195:1111111111111111111111111111111111111111111111111111111111111111
-- 196:1111111111111111111111111111111111111111111111111111111111111111
-- 197:1111111111111111111111111111111111111111111111111111111111111111
-- 198:1111111111111111111111111111111111111111111111111111111111111111
-- 199:1111111111111111111111111111111111111111111111111111111111111111
-- 200:1111111111111111111111111111111111111111111111111111111111111111
-- 201:1111111111111111111111111111111111111111111111111111111111111111
-- 202:1111111111111111111111111111111111111111111111111111111111111111
-- 203:1111111111111111111111111111111111111111111111111111111111111111
-- 204:1111111111111111111111111111111111111111111111111111111111111111
-- 205:1111111111111111111111111111111111111111111111111111111111111111
-- 206:1111111111111111111111111111111111111111111111111111111111111111
-- 207:1111111111111111111111111111111111111111111111111111111111111111
-- 208:1111111111111111111111111111111111111111111111111111111111111111
-- 209:1111111111111111111111111111111111111111111111111111111111111111
-- 210:1111111111111111111111111111111111111111111111111111111111111111
-- 211:1111111111111111111111111111111111111111111111111111111111111111
-- 212:1111111111111111111111111111111111111111111111111111111111111111
-- 213:1111111111111111111111111111111111111111111111111111111111111111
-- 214:1111111111111111111111111111111111111111111111111111111111111111
-- 215:1111111111111111111111111111111111111111111111111111111111111111
-- 216:1111111111111111111111111111111111111111111111111111111111111111
-- 217:1111111111111111111111111111111111111111111111111111111111111111
-- 218:1111111111111111111111111111111111111111111111111111111111111111
-- 219:1111111111111111111111111111111111111111111111111111111111111111
-- 220:1111111111111111111111111111111111111111111111111111111111111111
-- 221:1111111111111111111111111111111111111111111111111111111111111111
-- 222:1111111111111111111111111111111111111111111111111111111111111111
-- 223:1111111111111111111111111111111111111111111111111111111111111111
-- 224:1111111111111111111111111111111111111111111111111111111111111111
-- 225:1111111111111111111111111111111111111111111111111111111111111111
-- 226:1111111111111111111111111111111111111111111111111111111111111111
-- 227:1111111111111111111111111111111111111111111111111111111111111111
-- 228:1111111111111111111111111111111111111111111111111111111111111111
-- 229:1111111111111111111111111111111111111111111111111111111111111111
-- 230:1111111111111111111111111111111111111111111111111111111111111111
-- 231:1111111111111111111111111111111111111111111111111111111111111111
-- 232:1111111111111111111111111111111111111111111111111111111111111111
-- 233:1111111111111111111111111111111111111111111111111111111111111111
-- 234:1111111111111111111111111111111111111111111111111111111111111111
-- 235:1111111111111111111111111111111111111111111111111111111111111111
-- 236:1111111111111111111111111111111111111111111111111111111111111111
-- 237:1111111111111111111111111111111111111111111111111111111111111111
-- 238:1111111111111111111111111111111111111111111111111111111111111111
-- 239:1111111111111111111111111111111111111111111111111111111111111111
-- 240:1111111111111111111111111111111111111111111111111111111111111111
-- 241:1111111111111111111111111111111111111111111111111111111111111111
-- 242:1111111111111111111111111111111111111111111111111111111111111111
-- 243:1111111111111111111111111111111111111111111111111111111111111111
-- 244:1111111111111111111111111111111111111111111111111111111111111111
-- 245:1111111111111111111111111111111111111111111111111111111111111111
-- 246:1111111111111111111111111111111111111111111111111111111111111111
-- 247:1111111111111111111111111111111111111111111111111111111111111111
-- 248:1111111111111111111111111111111111111111111111111111111111111111
-- 249:1111111111111111111111111111111111111111111111111111111111111111
-- 250:1111111111111111111111111111111111111111111111111111111111111111
-- 251:1111111111111111111111111111111111111111111111111111111111111111
-- 252:1111111111111111111111111111111111111111111111111111111111111111
-- 253:1111111111111111111111111111111111111111111111111111111111111111
-- 254:1111111111111111111111111111111111111111111111111111111111111111
-- 255:1111111111111111111111111111111111111111111111111111111111111111
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
