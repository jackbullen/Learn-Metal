SRCS := $(wildcard src/*.mm)
OBJS := $(patsubst src/%.mm, obj/%.o, $(SRCS))
EXES := $(patsubst src/%.mm, bin/%, $(SRCS))

CC := clang++
CFLAGS := -Wall -v -std=c++17 -ObjC++
LDFLAGS := -framework Metal -framework Foundation -framework Cocoa -framework CoreGraphics -framework MetalKit

ifdef DEBUG
    CFLAGS += -g
else
    CFLAGS += -O2
endif

ifdef ASAN
    CFLAGS += -fsanitize=address
endif

all: $(OBJS) $(EXES)

bin/%: obj/%.o | bin
	$(CC) $(LDFLAGS) $< -o $@

obj/%.o: src/%.mm | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj:
	mkdir -p obj
bin:
	mkdir -p bin

clean:
	rm -rf obj bin