### make CXX=gcc-9 -B
### make CXX=clang-9 -B
CFLAGS = -O0 -g -std=iso9899:2018 -Wall -I include

GCC_CXXFLAGS = -DMESSAGE='"Compiled with GCC"'
CLANG_CXXFLAGS = -DMESSAGE='"Compiled with Clang"'
UNKNOWN_CXXFLAGS = -DMESSAGE='"Compiled with an unknown compiler"'

ifeq ($(CXX),g++)
	CXXFLAGS += $(GCC_CXXFLAGS)
else ifeq ($(CXX),clang)
	CXXFLAGS += $(CLANG_CXXFLAGS)
else
	CXXFLAGS += $(UNKNOWN_CXXFLAGS)
endif

### LDFLAGS
LDFLAGS = -lsqlite3

ifeq ($(OS),Windows_NT)
	LDFLAGS += -lws2_32
endif

UNAME_S = $(shell uname -s)

# strtok_r is provided by POSIX.1c-1995 and POSIX.1i-1995, however, with
# the POSIX_C_SOURCE=1 on Mac OS X is corresponding to the version of
# 1988 which is too old (defined in sys/cdefs.h)
CFLAGS += -D_POSIX_C_SOURCE=199506L

OUT = bin
EXEC = $(OUT)/facebooc
OBJS = \
	src/kv.o \
	src/response.o \
	src/template.o \
	src/main.o \
	src/bs.o \
	src/request.o \
	src/list.o \
	src/models/like.o \
	src/models/account.o \
	src/models/connection.o \
	src/models/session.o \
	src/models/post.o \
	src/server.o

deps := $(OBJS:%.o=%.o.d)

src/%.o: src/%.c
	$(CXX) $(CFLAGS) -o $@ -MMD -MF $@.d -c $<

$(EXEC): $(OBJS)
	mkdir -p $(OUT)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

.PHONY: all
all: $(EXEC)

.PHONY: run
run: $(EXEC)
	@echo "Starting Facebooc service..."
	@./$(EXEC) $(port)

.PHONY: clean
clean:
	$(RM) $(OBJS) $(EXEC) $(deps)

.PHONY: distclean
distclean: clean
	$(RM) db.sqlite3

-include $(deps)

clang-json-compilation-db: clean
	bear make CXX=clang-9 -B

git-add-upstream:
	git remote add upstream https://github.com/jserv/facebooc.git
	git remote -v

git-sync-upstream:
	git checkout master && git fetch upstream && git merge upstream/master && git checkout JH-dev
