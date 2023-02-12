SHELL 		:= /bin/bash
PYTHON		:= python3
MEMBER_ID 	:= https://data.oireachtas.ie/ie/oireachtas/member/id/Seán-Sherlock.D.2007-06-14
MID 		:= $(notdir $(MEMBER_ID))
DEBATES_XML := data/debates.d/$(MID).d/\%:

list 		:= $(foreach url,$(shell cat data/debates_$(MID).list.txt | sed 's,:,<colon>,g' | sed 's,/,<fwdslash>,g' ), data/debates.d/$(MID).d/$(url))
tsv_list	:= $(foreach f,$(list),$(dir $f)tsv/$(notdir $f).tsv)


utts: data/utterances_$(MID).tsv
test-utt: clean-test-utt $(firstword $(tsv_list))
	head "$(lastword $^)"
clean-test-utt:
	-rm "$(firstword $(tsv_list))"

data/utterances_$(MID).tsv: src/get-speeches-by-speaker $(tsv_list)
	cat "data/debates.d/$(MID).d/tsv/*.tsv" > "$@"

all: $(list)

data/debates.d/$(MID).d/tsv/%.tsv: $(@D) data/debates.d/$(MID).d/%
	$(PYTHON) src/get-speeches-by-speaker "$<" SeanSherlock > "$@"

data/debates.d/$(MID).d/tsv/:
	mkdir -p $@

data/debates.d/$(MID).d/%.xml:
	mkdir -p data/debates.d/$(MID).d/ ; \
	url=$$(echo "$(@F)" | sed 's,<colon>,:,g' | sed 's,<fwdslash>,/,g') ; \
	wget "$$url" -O "$@"

data/all_member_ids.txt: data/members1.json data/members2.json data/members3.json
	cat data/members{1,2,3}.json | \
		grep '"uri"' | \
		grep -o 'https://[^"]*/member/id/[^/"]*' | uniq > $@

member_debates: debates_$(notdir $(MEMBER_ID)).json

data/debates_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/debates?member_id=$(MEMBER_ID)&limit=9999" -O $@

data/debates_$(notdir $(MEMBER_ID)).list.txt:
	./src/extract_debate_uris_xml data/debates_$(notdir $(MEMBER_ID)).json | uniq > $@

data/member_info_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/members?member_id=$(MEMBER_ID)" -O $@

data/members1.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=0&limit=1000" -H  "accept: application/json" > $@

data/members2.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=1000&limit=1000" -H  "accept: application/json" > $@

data/members3.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=2000&limit=1000" -H  "accept: application/json" > $@
