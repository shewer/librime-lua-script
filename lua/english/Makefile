
# Makefile
# Shewer Lu, 2020-07-21 07:01
#
RIME= /mnt/c/Program\ Files\ \(x86\)/Rime/weasel-0.14.3
DEPLOYER= WeaselDeployer.exe
LUA=lua5.3
.PONEY: all update deploy test comment_tab 

all: update deploy 
	@echo "Makefile needs your attention"


# vim:ft=make
#
update:
	#cp -r lua/ $(Rime)/lua
	#cp lua/muti_reverse $(Rime)/lua/muti_reverse
	#cp lua/format2.lua  $(Rime)/lua
	#cp lua/reverse_switch.lua $(Rime)/lua
	#cp rime.lua $(Rime)
	cp english.schema.yaml  $(Rime)
	cp english.custom.yaml  $(Rime)
	cp english_plugin.yaml  $(Rime)
	rsync -vcru lua $(Rime)
	#cp lua/comment*.lua $(Rime)/lua


deploy:
	- rm $(WTMP)/rime* 
	$(RIME)/$(DEPLOYER) /deploy 

comment_tab:
	- ./comment.sh $(Rime)/build  comment_tab 

testlua:
	cd test 
	- pwd
	- $(LUA) format_test.lua


