# TD-scrape
Scrape public domain speeches from a Teachta Dála

# Number of speeches per td

```
$ wc -l data/utterances_*.tsv | sort -n -k1 | tail -n +3
```
| Num Speeches | Filename |
| ----: | :--- |
|    1607 | data/utterances_Cormac-Devlin.D.2020-02-08.tsv|
|    1880 | data/utterances_Catherine-Martin.D.2016-10-03.tsv|
|    2764 | data/utterances_Aodhán-Ó-Ríordáin.D.2011-03-09.tsv|
|    4971 | data/utterances_Joe-McHugh.S.2002-09-12.tsv|
|    7278 | data/utterances_Seán-Sherlock.D.2007-06-14.tsv|
|   17766 | data/utterances_Richard-Boyd-Barrett.D.2011-03-09.tsv|
|   23582 | data/utterances_Catherine-Connolly.D.2016-10-03.tsv|
|   27921 | data/utterances_Richard-Bruton.S.1981-10-08.tsv|
|   87769 | total|
