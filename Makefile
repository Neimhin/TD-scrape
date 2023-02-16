.ONESHELL:
SHELL 		:= /bin/bash
PYTHON		:= python3
MEMBER_ID 	:= https://data.oireachtas.ie/ie/oireachtas/member/id/Seán-Sherlock.D.2007-06-14
MID 		:= $(notdir $(MEMBER_ID))
MEMBER_TAG_REF := SeanSherlock
DEBATES_XML := data/debates.d/$(MID).d/\%:

DEBATE_DIR := data/debates.d/$(MID).d
list 		:= $(foreach url,$(shell cat data/debates_$(MID).list.txt | sed 's,:,<c>,g' | sed 's,/,<s>,g' ), $(DEBATE_DIR)/$(url))
TSV_DIR := $(DEBATE_DIR)/tsv
tsv_list	:= $(foreach f,$(list),$(dir $f)tsv/$(notdir $f).tsv)


data/debates.d/all-$(MEMBER_TAG_REF).csv:
	for f in data/debates.d/all/*.csv; do
		cat "$$f" | grep -P "#$(MEMBER_TAG_REF)\t"
	done > $@

all_xmls := $(wildcard data/debates.d/all/*.xml)
all_xmls_to_tsv := $(foreach f, $(all_xmls), $f.csv)

all_tsv: $(all_xmls_to_tsv)

data/debates.d/all/%.csv:
	./src/debate-xml-to-tsv "$(@D)/$*" > "$@"

data/debates.d/all-sorted.csv: data/debates.d/all-raw.csv
	cat $< | sort -u > $@

xmls:
	mkdir -p data/debates.d/all
	for f in data/debates.d/*.d/*.xml; do
		rsync $$f data/debates.d/all/`basename $$f`
	done

data/debates.d/all-raw.csv:
	for f in data/debates.d/*.d/*.xml; do
		./src/debate-xml-to-tsv $$f
	done > $@

everything: data/members_with_pId.tsv
	while IFS= read -r line; do
		tag_ref=`  echo $$line | awk '{print $$1}'`
		code=`     echo $$line | awk '{print $$2}'`
		member_id=`echo $$line | awk '{print $$3}'`
		echo $$tag_ref $$code $$member_id
		-make MEMBER_ID=$$member_id MEMBER_TAG_REF=$$tag_ref debates_list && make MEMBER_ID=$$member_id MEMBER_TAG_REF=$$tag_ref all && make -j MEMBER_ID=$$member_id MEMBER_TAG_REF=$$tag_ref utts
	done < $<


aodhan:
	member_id=`cat aodhan.tsv | grep -o 'https.*'`
	echo $$member_id
	make -j MEMBER_ID=$$member_id debates_list
	make MEMBER_ID=$$member_id MEMBER_TAG_REF=AodhanORiordan all
	make -j MEMBER_ID=$$member_id MEMBER_TAG_REF=AodhanORiordan utts

data/questions/after-2010/compiled.tsv: data/questions/after-2010-meta
	for f in data/questions/after-2010/*.json; do
		./src/scrape-questions $$f > $$f.tsv
	done
	cat data/questions/after-2010/*.json.tsv | sort -k 1 | sort -u > $@

data/questions.tsv: data/questions-meta
	for f in data/questions-meta-*.json; do
		./src/scrape-questions $$f > $$f.tsv
	done
	cat data/questions-meta-*.json.tsv | sort -k 1 | sort -u > $@

data/questions-meta: $(foreach range, $(shell seq 1 2000 30000), data/questions-meta-$(range).json)

data/questions-meta-%.json:
	skip=`echo $* | grep -o '^[[:digit:]]\+'`
	echo $$skip
	curl -X GET --location "https://api.oireachtas.ie/v1/questions?date_start=2000-01-01&date_end=2099-01-01&limit=2000&skip=$${skip}" -H  "accept: application/json" > $@

data/questions/after-2010-meta: $(foreach range, $(shell seq 0 2000 30000), data/questions/after-2010/$(range).json)

data/questions/after-2010/%.json:
	skip=`echo $* | grep -o '^[[:digit:]]\+'`
	echo $$skip
	curl -X GET --location "https://api.oireachtas.ie/v1/questions?date_start=2010-01-01&date_end=2099-01-01&limit=2000&skip=$${skip}" -H  "accept: application/json" > $@

utts: data/utterances_$(MID).tsv
EG := eg
test-utt: 
	$(PYTHON) src/get-speeches-by-speaker $(EG) $(MEMBER_TAG_REF)

data/utterances_$(MID).tsv: $(TSV_DIR) $(tsv_list) src/get-speeches-by-speaker backup-tsv
	for f in $(TSV_DIR)/*; do
		cat "$$f" >> "$@"
	done

$(TSV_DIR):
	mkdir -p $@

backup-tsv:
	-mv "data/utterances_$(MID).tsv" "data/utterances_$(MID).tsvBAK"

data/debates.d/$(MID).d/tsv/%.tsv: PROG := src/get-speeches-by-speaker
data/debates.d/$(MID).d/tsv/%.tsv: $(@D) data/debates.d/$(MID).d/% $(PROG)
	$(PYTHON) $(PROG) "$<" $(MEMBER_TAG_REF) > "$@"

data/debates.d/$(MID).d/tsv/:
	mkdir -p $@

all: $(list)
data/debates.d/$(MID).d/%.xml:
	mkdir -p data/debates.d/$(MID).d/ ; \
	url=$$(echo "$(@F)" | sed 's,<c>,:,g' | sed 's,<s>,/,g') ; \
	wget "$$url" -O "$@"

data/all_member_ids.txt: data/members1.json data/members2.json data/members3.json
	cat data/members{1,2,3}.json | \
		grep '"uri"' | \
		grep -o 'https://[^"]*/member/id/[^/"]*' | uniq > $@

member_debates: debates_$(MID).json

data/debates_$(MID).json:
	wget "https://api.oireachtas.ie/v1/debates?member_id=$(MEMBER_ID)&limit=9999" -O $@

debates_list: data/debates_$(MID).list.txt
data/debates_$(MID).list.txt: data/debates_$(MID).json
	./src/extract_debate_uris_xml $< | uniq > $@

data/member_info_$(notdir $(MEMBER_ID)).json:
	wget "https://api.oireachtas.ie/v1/members?member_id=$(MEMBER_ID)" -O $@

data/members_with_pId.tsv: data/members.tsv
	cat $< | grep -v -P "^None\t" > $@

data/members.tsv: $(foreach n,1 2 3,data/members$n.json.tsv)
	cat $^ | sort -u > $@

data/members%.json.tsv: data/members%.json
	./src/member-list $< > $@

data/members1.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=0&limit=1000" -H  "accept: application/json" > $@

data/members2.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=1000&limit=1000" -H  "accept: application/json" > $@

data/members3.json:
	curl -X GET "https://api.oireachtas.ie/v1/members?skip=2000&limit=1000" -H  "accept: application/json" > $@

data/all_member_refs.txt:
	for f in data/debates.d/Seán-Sherlock.D.2007-06-14.d/*; do
		cat $$f | ./src/refers-to ;
	done | sort -u > $@
