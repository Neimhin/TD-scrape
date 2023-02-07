SHELL=/bin/bash

MEMBER_ID=https://data.oireachtas.ie/ie/oireachtas/member/id/Seán-Sherlock.D.2007-06-14


all_member_ids.txt: members1.json members2.json members3.json
	cat members{1,2,3}.json | \
		grep '"uri"' | \
		grep -o 'https://[^"]*/member/id/[^/"]*' | uniq > $@
page = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16

$(test):
	echo $@

debate_list_page_all: $(foreach p,$(page),debate_list_page_$(p).html)


debate_deps.mk: debate_list.txt
	printf 'DEBATE_DEPS := ' > debate_deps.mk
	cat $< | sed ':a;N;$$!ba;s,\n, \\\n,g' >> debate_deps.mk

include debate_deps.mk

DEBATE_DEPS_FILE := $(foreach p,$(DEBATE_DEPS),debate_files/$(subst /,@,$p))

debate_text_all: $(DEBATE_DEPS_FILE)

debate_files/%: baseurl = https://www.oireachtas.ie
$(DEBATE_DEPS_FILE): debate_deps.mk
	curl --location $(baseurl)$(subst @,/,$(subst debate_files/,,$@)) > $@;


debate_list_page_%.html:
	curl "https://www.oireachtas.ie/en/debates/find/?page=$*&debateType=all&datePeriod=all&fromDate=21/01/1919&toDate=31/01/2023&term=/ie/oireachtas/house/dail/33&committee=&member=/ie/oireachtas/member/id/Seán-Sherlock.D.2007-06-14&resultsPerPage=100&pjax=1" > debate_list_page_$*.html

debate_list.txt: $(foreach p,$(page),debate_list_page_$(p).html)
	cat $^ | grep -o '"/en/debates/debate/[^"]*"' | grep -o '[^"]*' > $@

sean_sherlock_debate_uris.txt: debate_list_page.html
	cat $< | grep -o '"/en/debates/debate/[^"]*"' | grep -o '[^"]*' > $@

member_debates: debates_$(notdir $(MEMBER_ID)).json

debates_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/debates?member_id=$(MEMBER_ID)" -O $@

sherlock.json:
	wget "https://api.oireachtas.ie/v1/members?member_id=$(MEMBER_ID)" -O $@

members1.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=0&limit=1000" -H  "accept: application/json" > $@

members2.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=1000&limit=1000" -H  "accept: application/json" > $@

members3.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=2000&limit=1000" -H  "accept: application/json" > $@
