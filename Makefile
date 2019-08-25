# Build example:
# make -B all CXX=gcc-9
# make -B all CXX=clang-9
#
# How do you write a makefile for both clang and gcc?
#
# You can use CMake to achieve that. It is a better to use if you want to have portable code.
# https://stackoverflow.com/questions/50941196/how-do-you-write-a-makefile-for-both-clang-and-gcc
# https://stackoverflow.com/questions/10046114/in-cmake-how-can-i-test-if-the-compiler-is-clang
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

# NOTE: A substitution reference substitutes the value of a variable with alterations that you specify.
# https://stackoverflow.com/questions/26133377/understanding-makefile-with-c-o-and
# https://stackoverflow.com/questions/26065734/makefile-enforce-library-dependency-ordering/26066761
deps := $(OBJS:%.o=%.o.d)

# NOTE: $< when used in the "recipe", means "the first prerequisite" - the first thing after the : in the line.
# NOTE: $< is an automatic variable which means "the name of the first prerequisite".
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

# apt-get install bear
# https://github.com/rizsotto/Bear
# Alternative: https://github.com/nickdiego/compiledb
clang-json-compilation-db: clean
	bear make -B all CXX=clang-9

git-add-upstream:
	git remote add upstream https://github.com/jserv/facebooc.git
	git remote -v

git-sync-upstream:
	git checkout master && git fetch upstream && git merge upstream/master && git checkout JH-dev
