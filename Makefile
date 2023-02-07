SHELL=/bin/bash

MEMBER_ID=https://data.oireachtas.ie/ie/oireachtas/member/id/Seán-Sherlock.D.2007-06-14


data/all_member_ids.txt: data/members1.json data/members2.json data/members3.json
	cat data/members{1,2,3}.json | \
		grep '"uri"' | \
		grep -o 'https://[^"]*/member/id/[^/"]*' | uniq > $@

debate_list_page_all: $(foreach p,$(page),debate_list_page_$(p).html)

DEBATE_DEPS_FILE := $(foreach p,$(DEBATE_DEPS),debate_files/$(subst /,@,$p))

debate_text_all: $(DEBATE_DEPS_FILE)

debate_files/%: baseurl = https://www.oireachtas.ie
$(DEBATE_DEPS_FILE): debate_deps.mk
	curl --location $(baseurl)$(subst @,/,$(subst debate_files/,,$@)) > $@;


member_debates: debates_$(notdir $(MEMBER_ID)).json

debates_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/debates?member_id=$(MEMBER_ID)" -O $@

data/member_info_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/members?member_id=$(MEMBER_ID)" -O $@

data/members1.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=0&limit=1000" -H  "accept: application/json" > $@

data/members2.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=1000&limit=1000" -H  "accept: application/json" > $@

data/members3.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=2000&limit=1000" -H  "accept: application/json" > $@
