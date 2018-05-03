SQL_FILES = $(wildcard *.sql)
MARK_FILES = $(SQL_FILES:.sql=.mark)
%.mark: %.sql
	./load-script.sh $^

all: acc.mark $(MARK_FILES)
	@echo $^ >/dev/null

clean:
	rm *.mark

schema: acc.sql
	./load-script.sh $^
